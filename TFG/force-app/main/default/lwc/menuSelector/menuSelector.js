/**
 * @description       : Menu selector. Used to add and remove products to a Request. Used in record page of the Requests
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 10-12-2025
 * @last modified by  : Fernando Ibarra
**/
import { api,track, LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import getMenuItems from "@salesforce/apex/MenuSelectorController.getMenuItems";
import getSelectedItems from "@salesforce/apex/MenuSelectorController.getSelectedItems";
import saveSelectedProducts from "@salesforce/apex/MenuSelectorController.saveSelectedProducts";
import deleteSelectedProducts from "@salesforce/apex/MenuSelectorController.deleteSelectedProducts";

//Columns for the table of summary of products that are going to be added to the Request
const COLUMNS_TABLE_PRODUCTS_TO_ADD = [
    { label: 'Producto', fieldName: 'Name', type: 'text'},
    { label: 'Precio', fieldName: 'UnitPrice', type: 'currency'},
    { label: 'Cantidad', fieldName: 'Quantity', type: 'number', editable: true ,typeAttributes: {step: '1'}},
    { label: 'Precio Total', fieldName: 'TotalPrice', type: 'currency'},
];

export default class menuSelector extends LightningElement {

	showAddProductsModal = false;

	@track listOfProductsToAdd = [];//List of products to be added to the reqest
	addPorductColumnsList = COLUMNS_TABLE_PRODUCTS_TO_ADD;//Columns for the table
	isLoading = false;//Indicates when the spinner is shownd
	@api recordId; //Id of the request (Case SObject)
	menuMap;//Map with all the Key -> Product2Id, Value -> Product with image 
	@track menuList;//List with all the Products with image 
	selectedItemsMap;//Map with all the Key -> Product2Id, Value -> OrderItem
	@track selectedItemsList;//List with all the Selected OrderItems with image 
	totalPrice = 0;//Total price calculated for the request

	/**
	 * Obtain the id of the request (Only used in Request record page, when used in the community the Id is given by parameter from a parent component)
	 */
	@wire(CurrentPageReference)
	getPageReferenceParameters(currentPageReference) {
		if (currentPageReference) {
		  if(this.recordId == undefined || this.recordId == null){
			  this.recordId = currentPageReference.attributes.recordId || null;
		  }
		}
	}

	/**
	 * Connected Callback. Obtain the items available in the menu of the hotel and the items that are already selected in the request
	 */
	async connectedCallback(){
		this.isLoading = true;
		const data = await Promise.all([this.obtainMenuItems(), this.obtainSelectedItems()])
		this.fillOrderItemsImages();
		this.menuList = Object.values(this.menuMap);
		

	}

	/**
	 * Obtain the items available in the menu of the hotel in which belongs the request
	 */
	async obtainMenuItems(){
	  await getMenuItems({ requestId: this.recordId, })
		  .then(result => {
			this.menuMap = result;
		  })
		  .catch(error => {
			console.error('Error:', error);
		});
	}

	/**
	 * Connected Callback. Obtain the items that are already selected in the request
	 */
	async obtainSelectedItems(){
	  await getSelectedItems({ requestId: this.recordId, })
		  .then(result => {
			this.selectedItemsMap = result
		  })
		  .catch(error => {
			console.error('Error:', error);
		});
	}

	/**
	 * Add the image related to the product when the product is added to the request
	 */
	fillOrderItemsImages(){
		this.totalPrice = 0;
		for (const itemKey of Object.keys(this.selectedItemsMap)) {
			this.selectedItemsMap[itemKey]['ImageURL'] = this.menuMap[itemKey]['ImageURL'] ?? '';
			this.selectedItemsMap[itemKey]['Name'] = this.menuMap[itemKey]['Name'] ?? '';
			this.totalPrice += this.selectedItemsMap[itemKey]['TotalPrice'] ?? 0;
		}
		this.selectedItemsList = Object.values(this.selectedItemsMap);
		this.isLoading = false;
	}

	/**
	 * Add the selected product to the list of products to be added to the request (without inserting into database yet)
	 */
	handleAddProduct(event){
		// this.isLoading = true;
		//Obtain the id of the product selected
		const productId = event.currentTarget.dataset.id;

		//If the product have been  selected for being added
		const productIndexInList = this.listOfProductsToAdd.findIndex(product => {return product.Product2Id === productId });
		if(productIndexInList !== -1){
			//Add 1 to the selected quantity, update the total price for the product and exit this method 
			const menuItem = this.listOfProductsToAdd[productIndexInList];
			menuItem.Quantity += 1;
			menuItem.TotalPrice = menuItem.UnitPrice * menuItem.Quantity;
			return 
		}

		//If the product have not been selected for being added, add the product to the list of products to be added
		const menuItem = {...this.menuMap[productId]};
		if(menuItem == undefined) {
			this.template.querySelector('c-custom-toast').showToast('error', 'Error selecting the product');
			return;
		}

		menuItem.Quantity = 1;
		menuItem.TotalPrice = menuItem.UnitPrice;

		this.listOfProductsToAdd.push(menuItem);

		// this.template.querySelector('c-custom-toast').showToast('success', 'Product added successfully');
		// this.isLoading = false;
	}

	/**
	 * Modify the quantity of a selected product that will be added to the request (without inserting into database yet)
	 */
	handleModifyProductQuantity(event){
		const productId = event.currentTarget.dataset.id;
		const operation = event.currentTarget.dataset.operation;
		const menuItem = this.listOfProductsToAdd.find(product => {return product.Id === productId })
		if(menuItem == undefined){
			this.template.querySelector('c-custom-toast').showToast('error', 'Error updating the quantity');
			return;
		}
		if(operation == 'substract'){
			menuItem.Quantity -= 1;
			if(menuItem.Quantity < 1){
				this.listOfProductsToAdd = this.listOfProductsToAdd.filter(product => product.Id !== productId)
				return;
			}
			menuItem.TotalPrice = menuItem.UnitPrice * menuItem.Quantity;
		}
		else if (operation == 'add'){
			menuItem.Quantity += 1;
			menuItem.TotalPrice = menuItem.UnitPrice * menuItem.Quantity;
		}

	}

	/**
	 * Make the DML save for the selected products to be added
	 */
	async handleSaveSelectedProducts(){
		this.isLoading = true;
		//Set the correct format for the data in order to insert them into Salesforce SObjects
		let productsToInsert = [];
		for (const product of this.listOfProductsToAdd) {
			productsToInsert.push(
				{
					sobjectType: "OrderItem",
  					Quantity: product.Quantity,
  					Product2Id: product.Product2Id,
					PricebookEntryId: product.Id,
					UnitPrice: product.UnitPrice
				}
			)
		}
		//Save the selected products
		await saveSelectedProducts({ requestId: this.recordId, itemsToAdd: productsToInsert })
		  .then(result => {
			this.template.querySelector('c-custom-toast').showToast('success', 'Product added successfully');
			this.closeAddProductsModal();
		  })
		  .catch(error => {
			console.error('Error:', error);
			this.template.querySelector('c-custom-toast').showToast('error', 'Error adding the product');
			return;
		});
		//Refresh the info of the selected products for the request after saving products in the request
		await this.obtainSelectedItems();
		//Add the proper images to each selected product
		this.fillOrderItemsImages();

	}

	/**
	 * Make the DML delete for the selected products
	 */
	async handleRemoveProducts(event){
		this.isLoading = true;
		//Set the correct format for the data in order to insert them into Salesforce SObjects
		const lineItemId = event.currentTarget.dataset.id;
		const item = this.selectedItemsMap[lineItemId];
		let productsToRemove = [];
		productsToRemove.push(
			{
				sobjectType: "OrderItem",
				Id: item.Id
			}
		)
		//Delete the selected products
		await deleteSelectedProducts({ itemsToDelete: productsToRemove })
		  .then(result => {
			this.template.querySelector('c-custom-toast').showToast('success', 'Product removed successfully');
		  })
		  .catch(error => {
			console.error('Error:', error);
			const msg = error.body.pageErrors[0].message ?? 'Error removing the product'
			this.template.querySelector('c-custom-toast').showToast('error', msg);
			return;
		});
		//Refresh the info of the selected products for the request after removing products in the request
		await this.obtainSelectedItems();
		//Add the proper images to each selected product
		this.fillOrderItemsImages();

	}

	/**
	 * Open the modal used to add products to the request
	 */
	handleOpenAddProductsModal(){
		this.showAddProductsModal =true;
	}

	/**
	 * Close the modal used to add products to the request
	 */
	closeAddProductsModal(){
		this.showAddProductsModal = false;
		this.listOfProductsToAdd = [];
	}

}