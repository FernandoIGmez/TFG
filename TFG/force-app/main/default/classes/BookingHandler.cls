/**
 * @description       : Handler for the Triger of Booking__c SObject
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 01-04-2026
 * @last modified by  : Fernando Ibarra
**/
public with sharing class BookingHandler {
    
    /**
    * @description Fills UUID Filed in the booking only when the booking is active (The check in has been done but not the check out). The UUID is used to generate the link for the clients to access the booking information. 
    * @author Fernando Ibarra | 18-01-2026 
    * @param newList 
    * @param oldMap 
    **/
    public static void updateUUIDField(List<Booking__c> newList, Map<Id,Booking__c> oldMap){
        for (Booking__c booking : newList) {
            Booking__c oldBooking = oldMap.get(booking.Id);
            //When the check-in is done, fill the UUID
            if(booking.CheckIn__c != oldBooking.CheckIn__c && booking.CheckIn__c){
                booking.UUID__c = UUID.randomUUID().toString();
            }
            //When the check-out is done, remove the UUID
            if(booking.CheckOut__c != oldBooking.CheckOut__c && booking.CheckOut__c){
                booking.UUID__c = null;
            }
        }
    }
}