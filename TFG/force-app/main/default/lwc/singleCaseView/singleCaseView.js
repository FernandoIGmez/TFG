import { LightningElement, track, api } from 'lwc';
import getCaseInfo from "@salesforce/apex/ClientsPageController.getCaseInfo";
import getPicklistValues from "@salesforce/apex/ClientsPageController.getPicklistValues";
import updateCase from "@salesforce/apex/ClientsPageController.updateCase";
import moveCaseToInProgress from "@salesforce/apex/ClientsPageController.moveCaseToInProgress";

export default class SingleCaseView extends LightningElement {

    isLoading = false;
    caseId;
    // fields = ["Case.CaseNumber", "Case.Description", "Case.Subject", "Case.Category" ]
    @api selectedCase = {};
    @track caseInfo = {};

    categories = [];
    priorities = [];
    statuses = [];
    @track selectedCategories = [];
    requestIsInDraft = false;

    async connectedCallback(){
        this.isLoading = true;
        this.caseInfo = {...this.selectedCase};
        this.caseId = this.caseInfo.Id;
        this.checkIfRequestIsInDraft();
        await Promise.all([this.obtainCategoryPicklistValues(), this.obtainPriorityPicklistValues(), this.obtainStatusPicklistValues()])
        this.updatePathInfo();
        this.isLoading = false;
    }

    async obtainCaseInfo(){
        await getCaseInfo({ caseId: this.caseId })
            .then(result => {
                console.log('Result', result);
                this.caseInfo = result;
                this.caseInfo.CreatedDate = this.caseInfo.CreatedDate.slice(0,10);
                this.checkIfRequestIsInDraft();
                this.selectedCategories = [];
                if(this.caseInfo.hasOwnProperty('Category__c')){
                        this.selectedCategories = this.caseInfo['Category__c'].split(';');
                }
            })
            .catch(error => {
                console.error('Error:', error);
        });
    }

    async obtainCategoryPicklistValues(){
        await getPicklistValues({fieldName : 'Category__c'})
            .then(result => {
                console.log('Result', result);
                this.categories = result;
            })
            .catch(error => {
                console.error('Error:', error);
        });
    }

    async obtainPriorityPicklistValues(){
        await getPicklistValues({fieldName : 'Priority'})
            .then(result => {
                console.log('Result', result);
                this.priorities = result;
            })
            .catch(error => {
                console.error('Error:', error);
        });
    }

    async obtainStatusPicklistValues(){
        await getPicklistValues({fieldName : 'Status'})
            .then(result => {
                console.log('Result', result);
                this.statuses = result;
            })
            .catch(error => {
                console.error('Error:', error);
        });
    }

    handleFieldChange(event){
        const newValue = event.detail.value;
        const element = event.currentTarget.dataset.element;
        switch (element) {
            case 'Category':
                this.caseInfo['Category__c'] = newValue.join(';')
                break;
            case 'Subject': 
            case 'Description': 
            case 'Priority':
                this.caseInfo[element] = newValue;
                break;
            default:
                break;
        }
    }

    async handleSaveChanges(){
        this.isLoading = true;
        let caseToUpdate = { ...this.caseInfo};
        delete caseToUpdate.CreatedDate;
        caseToUpdate.sobjectType = 'Case';

        await updateCase({ caseToUpdate: caseToUpdate })
          .then(result => {
            console.log('Result', result);
            this.template.querySelector('c-custom-toast').showToast('success', 'Guardado completado con éxito');
          })
          .catch(error => {
            console.error('Error:', error);
            this.template.querySelector('c-custom-toast').showToast('error', 'Error al guardar');
        });
        
        this.isLoading = false;
        this.dispatchEvent(new CustomEvent("updaterecord"));

    }

    async handleConfirmRequest(){
        this.isLoading = true;

        let success = false;
        await moveCaseToInProgress({ caseId: this.caseId })
          .then(result => {
            success = true;
            this.template.querySelector('c-custom-toast').showToast('success', 'Guardado completado con éxito');
            
            
          })
          .catch(error => {
            console.error('Error:', error);
            this.template.querySelector('c-custom-toast').showToast('error', 'Error al guardar');
        });

        if(!success) return;

        await this.obtainCaseInfo();
        this.updatePathInfo();

        this.isLoading = false;
        this.dispatchEvent(new CustomEvent("updaterecord"));
    }

    checkIfRequestIsInDraft(){
        this.requestIsInDraft = false;
        if(this.caseInfo.Status == 'New') this.requestIsInDraft = true;
    }

    updatePathInfo(){
        this.template.querySelector('c-path').updatePath();
    }

    handleCloseModal(){
        this.dispatchEvent(new CustomEvent("closemodal"));
    }
}