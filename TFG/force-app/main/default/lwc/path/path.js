import { LightningElement, api } from 'lwc';

export default class Path extends LightningElement {
    @api stages = [];
    @api actualStage = '';

    stagesStatus = [];

    @api updatePath(){
        this.stagesStatus = [];
        let actualStageFound = false;
        for (const stage of this.stages) {
            if(stage.value == 'Cancelled') continue;
            let stageInfo = { 'title': stage.label};
            if(stage.value == this.actualStage){
                stageInfo.cssClass = 'slds-path__item slds-is-current slds-is-active';
                actualStageFound = true;
            }
            else if(!actualStageFound){
                stageInfo.cssClass = 'slds-path__item slds-is-complete';
            }
            else {
                stageInfo.cssClass = 'slds-path__item slds-is-incomplete';
            }
            this.stagesStatus.push(stageInfo);
        }
    }
}