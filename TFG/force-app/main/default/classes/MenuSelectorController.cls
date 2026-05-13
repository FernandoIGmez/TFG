/**
 * @description       : Controller of the component that handles the addition/remove of items to a Rsequest (Case). We use without sharing because altough other users could have permissions, the guest user that clients use have no permissions for most of the functionallities done in this class.
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 03-04-2026
 * @last modified by  : Fernando Ibarra
**/
public without sharing class MenuSelectorController {
    
    /**
    * @description Provides the menu items that are asociated to the request, which are the items of the pricebook of the Hotel (Account)
    * @author Fernando Ibarra | 23-10-2025 
    * @param requestId Id of the Request
    * @return List<EntryWrapper> 
    **/
    @AuraEnabled
    public static Map<Id,EntryWrapper> getMenuItems(Id requestId){
        //Obtains the Pricebook2Id and the External Id of the Hotel related with the request 
        Case c = [SELECT OrderId__r.Pricebook2Id, Account.ExternalId__c FROM Case WHERE Id =: requestId ];
        Id pricebookId = c.OrderId__r.Pricebook2Id;
        String hotelExternalId = '%'+c.Account.ExternalId__c + '.%'; 
        Map<Id,EntryWrapper> menuItems = new  Map<Id,EntryWrapper>();
        //Query the pricebook entries for the hotel using the pricebookId
        for (PricebookEntry entry : [SELECT Id, UnitPrice, Product2Id, Product2.Name FROM PricebookEntry WHERE Pricebook2Id =: pricebookId]) {
            menuItems.put(entry.Product2Id, new EntryWrapper(entry.Id, entry.Product2Id, entry.Product2.Name, entry.UnitPrice, ''));
        }
        
        //Query the images URLs for all the products in the pricebook.
        //To do this we need to have a image related in the product2 record, and the name of the image needs to have the 'external id' of the hotel in the name.
        //Also for Guest User form the Digital Experience to be able to view the image, this image should be added to the "Product Images" library (Files -> Libraries -> Product Images)
        for (ContentVersion productImage : [SELECT VersionDataUrl, FirstPublishLocationId FROM ContentVersion WHERE FirstPublishLocationId IN: menuItems.keySet() AND PathOnClient LIKE: hotelExternalId]) {
            menuItems.get(productImage.FirstPublishLocationId).ImageURL = productImage.VersionDataUrl;
        }

        return menuItems;
    }

    /**
    * @description Get the selected products for a Request.
    * @author Fernando Ibarra | 03-04-2026 
    * @param requestId 
    * @return Map<Id, OrderItem> 
    **/
    @AuraEnabled
    public static Map<Id, OrderItem> getSelectedItems(Id requestId){
        Map<Id, OrderItem> itemsMap = new Map<Id,OrderItem>();
        for (OrderItem item : [SELECT Id, UnitPrice, TotalPrice, Product2Id, Quantity FROM OrderItem WHERE OrderId IN (SELECT OrderId__c FROM Case WHERE Id =: requestId)]) {
            itemsMap.put(item.Product2Id, item);
        }
        return itemsMap;
    }

    /**
    * @description Makes an Upsert of a list of products for a specific request. If some products were added previously to this save, add them to the old ones.
    * @author Fernando Ibarra | 03-04-2026 
    * @param requestId 
    * @param itemsToAdd 
    **/
    @AuraEnabled
    public static void saveSelectedProducts(Id requestId, List<OrderItem> itemsToAdd){
        //Obtains the id of the order
        Id orderId =  [SELECT OrderId__c FROM Case WHERE Id =: requestId LIMIT 1 ].OrderId__c;
        Map<Id, OrderItem> itemsAlreadyAdded = new Map<Id,OrderItem>();
        //Store in a  map all the items that were already added to the order
        for (OrderItem item : [SELECT Id, Quantity, Product2Id, PricebookEntryId, UnitPrice FROM OrderItem WHERE OrderId =: orderId]) {
            itemsAlreadyAdded.put(item.Product2Id, item);
        }
        //Loop all the new items to be added
        for (OrderItem item : itemsToAdd) {
            OrderItem previusItem = itemsAlreadyAdded.get(item.Product2Id);
            //If this item was added previously to the order, modify the orderItem line with the addition of the new items added
            if(previusItem != null){
                item.Id = previusItem.Id;
                item.Quantity = previusItem.Quantity + item.Quantity;
            }
            //If this item was not added previously to the order, set the orderId to the new line of items
            else{
                item.OrderId = orderId;
            }
        }

        upsert itemsToAdd;
    }

    @AuraEnabled
    public static void deleteSelectedProducts(List<OrderItem> itemsToDelete){
        delete itemsToDelete;
    }

    /**
     * This class is used to send to the LWC all the information about a single product for a hotel: Price, Image, Name and needed Id's (Product2 Id and PricebookEntry Id)
     */
    public class EntryWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public Id Product2Id;
        @AuraEnabled public Decimal UnitPrice;
        @AuraEnabled public String ImageURL;
        @AuraEnabled public String Name;
        
        public EntryWrapper(Id Id, Id Product2Id, String Name, Decimal UnitPrice, String ImageURL){
            this.Id = Id;
            this.Product2Id = Product2Id;
            this.UnitPrice = UnitPrice;
            this.ImageURL = ImageURL;
            this.Name = Name;
        }
    }
}