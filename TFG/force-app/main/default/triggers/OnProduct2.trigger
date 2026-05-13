/**
 * @description       : 
 * @author            : Fernando Ibarra
 * @group             : 
 * @last modified on  : 09-10-2025
 * @last modified by  : Fernando Ibarra
**/
trigger OnProduct2 on Product2 (before insert, after insert, before update, after update , before delete, after delete) {

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            Product2Handler.addProductToStandardPriceBook(Trigger.new);
        }
    }

}