/**
 * @description       : 
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 09-10-2025
 * @last modified by  : Fernando Ibarra
**/
public with sharing class Product2Handler {
    
    
    public static void addProductToStandardPriceBook(List<Product2> newList){
        //First, obtain the id of the standard pricebook
        Id pricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1].Id;
        List<PricebookEntry> entriesToCreate = new List<PricebookEntry>();
        for (Product2 prod : newList) {
            entriesToCreate.add(new PricebookEntry(Pricebook2Id = pricebookId , Product2Id = prod.Id, UnitPrice = 1, IsActive = true));
        }
        //Insert the entries
        insert entriesToCreate;
    }
}