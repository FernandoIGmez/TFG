/**
 * @description       : Handler for the Triger of Case(Request) SObject
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 18-01-2026
 * @last modified by  : Fernando Ibarra
**/
public without sharing class CaseHandler {

    /**
    * @description Fill the accountId field (lookup to Hotel SObject) and contactId using their values from the booking info 
    * @author Fernando Ibarra | 18-01-2026 
    * @param newList 
    **/
    public static void fillRelatedAccount(List<Case> newList){
        Set<Id> bookingIds = new Set<Id>();
        //Obtain the id of the bookings related to the Requests (Cases)
        for (Case singleCase : newList) {
            bookingIds.add(singleCase.BookingId__c);
        }
        //Obtain the id of the hotels as a map with key -> BookingId value -> HotelId
        Map<Id,Booking__c> bookingInfo = new Map<Id,Booking__c>();
        for ( Booking__c booking : [SELECT Room__r.Hotel__c, Guest__c FROM Booking__c WHERE Id IN: bookingIds]) {
            bookingInfo.put(booking.Id, booking);
        }
        //Fill in the value of the field AccountId of the Requests (Cases)
        for (Case singleCase : newList) {
            singleCase.AccountId = bookingInfo?.get(singleCase.BookingId__c)?.Room__r?.Hotel__c;
            singleCase.ContactId = bookingInfo?.get(singleCase.BookingId__c)?.Guest__c;
        }
    }

    /**
    * @description Creates the empty Order record to allow users to link menu items to the request
    * @author Fernando Ibarra | 18-01-2026 
    * @param newList 
    **/
    public static void createLinkedOrder(List<Case> newList){
        //Obtain the ids of the hotels
        Set<Id> hotelIds = new Set<Id>();
        for (Case singleCase : newList) {
            hotelIds.add(singleCase.AccountId);
        }
        //Obtain the active pricebook for each hotel. 
        Map<Id,Id> activePricebookPerHotel = new Map<Id,Id>();
        for (Pricebook2 pricebook : [SELECT Id, HotelId__c FROM Pricebook2 WHERE HotelId__c IN: hotelIds]) {
            activePricebookPerHotel.put(pricebook.HotelId__c, pricebook.Id);
        }
        //Creates an empty order linked to each case
        Map<Id,Order> ordersToCreatePerCase = new Map<Id,Order>();
        for (Case singleCase : newList) {
            Order newOrder = new Order();
            newOrder.AccountId = singleCase.AccountId;
            newOrder.Status = 'Draft';
            newOrder.EffectiveDate = Date.today();
            newOrder.Pricebook2Id = activePricebookPerHotel.get(singleCase.AccountId);
            ordersToCreatePerCase.put( singleCase.Id, newOrder);
        }

        insert ordersToCreatePerCase.values();
        for (Case singleCase : newList) {
            singleCase.OrderId__c = ordersToCreatePerCase?.get(singleCase.Id)?.Id;
        }
    }

    /**
    * @description Set the hotel queue as owner of the Case (Request) when a request that comes directly from the client (via web) is set as 'In Progress'.
    * @author Fernando Ibarra | 18-01-2026 
    * @param newList 
    * @param oldMap 
    **/
    public static void routeCaseToHotelQueue(List<Case> newList, Map<Id,Case> oldMap){
        List<Case> casesToRouteToQueue = new List<Case>();
        Set<Id> hotelsToBeingRoute = new Set<Id>();
        for (Case actualCase : newList) {
            Case oldCase = oldMap.get(actualCase.Id);
            //We just route the cases created by clients that are moved from draft status to the queue
            if(actualCase.Status != oldCase.Status && actualCase.Status.equals('InProgress') && actualCase.Origin.equals('Web')){
                casesToRouteToQueue.add(actualCase);
                hotelsToBeingRoute.add(actualCase.AccountId);
            }
        }
        //If there are no cases to route exit this method
        if(casesToRouteToQueue.isEmpty()) return;

        //Obtain the external ids of the hotels
        Map<Id,String> externalIdPerHotelId = new Map<Id,String>();
        for (Account hotel : [SELECT Id, ExternalId__c FROM Account]) {
            externalIdPerHotelId.put(hotel.Id,hotel.ExternalId__c);
        }

        //If there are no cases to route exit this method
        if(externalIdPerHotelId.isEmpty()) return;

        //Use the external Id of the hotels to obtain the queues (The DeveloperName of a hotel's queue is the externalId of the hotel)
        Map<String, Id> hotelQueuePerHotelExternalId = new Map<String, Id>();
        for (Group queue : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN: externalIdPerHotelId.values()]) {
            hotelQueuePerHotelExternalId.put(queue.DeveloperName, queue.Id);
        }
        //Update the ownerId of each case to route with the id of it's hotel's queue
        for (Case actualCase : casesToRouteToQueue) {
            Id hotelQueueId = hotelQueuePerHotelExternalId.get(externalIdPerHotelId.get(actualCase.AccountId));
            if(hotelQueueId == null) continue;
            actualCase.OwnerId = hotelQueueId;
        }

    }

    /**
    * @description When a Request created from a user is moved from draft, launch an integration that translates the desctription of the Request
    * @author Fernando Ibarra | 18-01-2026 
    * @param newList 
    * @param oldMap 
    **/
    public static void translateDescription(List<Case> newList, Map<Id,Case> oldMap){
        Set<Id> casesIdsToTranslate = new Set<Id>();
        for (Case newCase : newList) {
            Case oldCase = oldMap.get(newCase.Id);
            if(newCase.Origin.equals('Web') && newCase.Status.equals('InProgress') && newCase.Status != oldCase.Status && String.isNotBlank(newCase.Description)){
                casesIdsToTranslate.add(newCase.Id);
            }
        }

        if(casesIdsToTranslate.isEmpty()) return;
        
        TranslationApiCallout.makeCallout(casesIdsToTranslate);
    }
    
}