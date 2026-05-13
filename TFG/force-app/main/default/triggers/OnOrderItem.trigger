/**
 * @description       : 
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 18-11-2025
 * @last modified by  : Fernando Ibarra
**/
trigger OnOrderItem on OrderItem (before insert, before update, before delete) {

    if(Trigger.isBefore){
        if(Trigger.isInsert){
            OrderItemHandler.validateDMLAction(Trigger.new, Trigger.old);
        }
        else if(Trigger.isUpdate){
            OrderItemHandler.validateDMLAction(Trigger.new, Trigger.old);
        }
        else if(Trigger.isDelete){
            OrderItemHandler.validateDMLAction(Trigger.new, Trigger.old);
        }
    }
    
}