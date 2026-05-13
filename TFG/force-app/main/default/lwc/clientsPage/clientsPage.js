/**
 * @description       : LWC Of the clients page that is shown for clients (Guest Users) in the Digital Experience Web Page
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 03-04-2026
 * @last modified by  : Fernando Ibarra
**/
import { LightningElement, track } from 'lwc';
import validateBooking from "@salesforce/apex/ClientsPageController.validateBooking";
import getCasesInfo from "@salesforce/apex/ClientsPageController.getCasesInfo";
import createNewCase from "@salesforce/apex/ClientsPageController.createNewCase";

export default class ClientsPage extends LightningElement {

	showPage = false;//Shows the whole page. Set to true if the received UUID for the booking exist at the moment as a active booking in Salesforce.
	showModal = false;//Shows the modal with the infomration about a single Request
	isLoading = true;//Shows a loading spinner

	caseList = [];//List of requests to be shown in the page
	selectedCase;//Selected case to be shown in the modal

	bookingId = 'Invalid';//UUID of the booking
		
	urlParameters;//Parameters received via URL

	/**
	 * Connected Callback. Obtains the UUID from the URL 
	 */
	async connectedCallback() {
		this.urlParameters = Object.fromEntries(new URLSearchParams(location.search));
		console.log('URL');
		console.log(this.urlParameters);
		this.bookingId = this.urlParameters.c__Id ?? 'Invalid';
		
		await this.retrieveCasesInfo();
	}
	
	/**
	 * Validates if the booking is active and exist in salesforce. If so, activate the page and retrieve all the requests that are already in the system for that booking
	 */
	async retrieveCasesInfo(){
		this.isLoading = true;

		//Validates if the booking exist and is active
		await validateBooking({ bookingId: this.bookingId })
		  .then(result => {
			//If the booking is active, load the page
			this.showPage = true;
		  })
		  .catch(error => {
			//If the booking not exist or is not active, do not load the page
			this.showPage = false;
			return;
		});

		//Obtains the list of requests of the booking
		await getCasesInfo({ bookingId: this.bookingId })
		  .then(result => {
			console.log('Result', result);
			this.isLoading = false;
			this.caseList = result;
			for (const actualCase of this.caseList) {
				actualCase.CreatedDate = actualCase.CreatedDate.slice(0,10);
			}
		  })
		  .catch(error => {
			this.isLoading = false;
			console.error('Error:', error);
		});
	}

	/**
	 * When the user clicks on the 'view' button on a request, open the modal with that request's information
	 */
	handleOpenCaseView(event){
		const caseId = event.currentTarget.dataset.id;
		this.selectedCase = this.caseList.find(caseToFind => {return caseToFind.Id === caseId })
		this.showModal = true;
	}

	/**
	 * When the user clicks on the 'close' button on a the modal, close the modal
	 */
	handleCloseModal(){
		this.showModal = false;
	}

	/**
	 * When the user clicks on the 'New Request' Button, creates a new request and show it in the modal.
	 */
	async handleCreateNewCase(){
		this.isLoading = true;
		
		await createNewCase({ bookingId: this.bookingId })
		  .then(result => {
			console.log('Result', result);
			this.selectedCase = result;
			this.showModal = true;
			this.handleUpdateInfo();
		  })
		  .catch(error => {
			console.error('Error:', error);
		});

		this.isLoading = false;
	}

	/**
	 * When the user clicks on the 'refresh' button in the main page, refresh the info of all the requests
	 */
	handleUpdateInfo(){
		this.retrieveCasesInfo();
	}

}