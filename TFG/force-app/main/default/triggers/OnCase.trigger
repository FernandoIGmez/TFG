/**
 * @description       : 
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 09-12-2025
 * @last modified by  : Fernando Ibarra
**/
trigger OnCase on Case ( before insert, after insert, before update, after update , before delete, after delete ) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            CaseHandler.fillRelatedAccount(Trigger.new);
            CaseHandler.createLinkedOrder(Trigger.new);
        }
        if(Trigger.isUpdate){
            CaseHandler.routeCaseToHotelQueue(Trigger.new, Trigger.oldMap);
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            CaseHandler.translateDescription(Trigger.new, Trigger.oldMap);
        }
    }
}