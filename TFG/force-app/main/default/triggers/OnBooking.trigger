/**
 * @description       : Trigger for Booking__c Object. Fills UUID Filed in the booking only when the booking is active (The check in has been done but not the check out)
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 01-04-2026
 * @last modified by  : Fernando Ibarra
**/
trigger OnBooking on Booking__c (before update) {
    if(Trigger.isBefore){
        if(Trigger.isUpdate){
            BookingHandler.updateUUIDField(Trigger.new, Trigger.oldMap);
        }
    }
}