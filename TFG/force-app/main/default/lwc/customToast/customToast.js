import { LightningElement, api, track } from 'lwc';

export default class CustomToast extends LightningElement {
    @track type;
    @track message;
    @track showToastBar = false;
    @api autoCloseTime = 5000; // Close after 5 seconds by default

    @api
    showToast(type, message) {
        this.type = type;  // Error, Success, etc.
        this.message = message;  // The text to show
        this.showToastBar = true;  // Show the toast

        // Close the toast after the time is up
        setTimeout(() => {
            this.closeModel();
        }, this.autoCloseTime);
    }

    closeModel() {
        this.showToastBar = false;  // Hide the toast
        this.type = '';
        this.message = '';
    }

    get getIconName() {
        return 'utility:' + this.type;  // Icon based on message type
    }

    get innerClass() {
        return 'slds-icon_container slds-icon-utility-' + this.type;
    }

    get outerClass() {
        return 'slds-notify slds-notify_toast slds-theme_' + this.type;
    }
}