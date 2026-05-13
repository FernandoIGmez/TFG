/**
 * @description       : Handler class for the OrderItem trigger.
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 03-04-2026
 * @last modified by  : Fernando Ibarra
**/
public without sharing class OrderItemHandler {
    
    /**
    * @description Id the DML action of OrderItems are done in a order from a request that is not in "New" status, avoid the dml 
    * @author Fernando Ibarra | 03-04-2026 
    * @param newItems 
    * @param oldItems 
    **/
    public static void validateDMLAction(List<OrderItem> newItems, List<OrderItem> oldItems){
        Set<Id> orderIds = new Set<Id>();
        List<OrderItem> itemsToCheck = new List<OrderItem>();
        if(newItems != null ){
            //Loop For INSERT, UPDATE
            for (OrderItem item : newItems) {
                orderIds.add(item.OrderId);
                itemsToCheck.add(item);
            }
        }
        else if( oldItems != null){
            //Loop For UPDATE, DELETE
            for (OrderItem item : oldItems) {
                orderIds.add(item.OrderId);
                itemsToCheck.add(item);
            }
        }

        Map<Id,Boolean> isRequestAvailableToEditItems = new Map<Id,Boolean>();
        for (Case request : [SELECT OrderId__c, Status FROM Case WHERE OrderId__c IN: orderIds]) {
            if(request.Status.equals('New')) isRequestAvailableToEditItems.put(request.OrderId__c, true);
            else isRequestAvailableToEditItems.put(request.OrderId__c, false);
        }

        for (OrderItem item : itemsToCheck) {
            if(!isRequestAvailableToEditItems.get(item.OrderId)){
                item.addError('No se puede modificar una petición que se encuentra en progreso');
            }
        }
    }
}