/*
 * Really easy field validation with Prototype
 * http://tetlaw.id.au/view/javascript/really-easy-field-validation
 * Andrew Tetlaw
 * Version 1.5.4.1 (2007-01-05)
 *
 * Copyright (c) 2007 Andrew Tetlaw
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

var Validator = Class.create();


Validator.prototype = {
    initialize : function(className, error, test, options) {
        if(typeof test == 'function'){
            this.options = $H(options);
            this._test = test;
        } else {
            this.options = $H(test);
            this._test = function(){
                return true
            };
        }
        this.error = error || 'Validation failed.';
        this.className = className;
    },
    test : function(v, elm) {
        return (this._test(v,elm) && this.options.all(function(p){
            return Validator.methods[p.key] ? Validator.methods[p.key](v,elm,p.value) : true;
        }));
    }
}
Validator.methods = {
    pattern : function(v,elm,opt) {
        return Validation.get('IsEmpty').test(v) || opt.test(v)
    },
    minLength : function(v,elm,opt) {
        return v.length >= opt
    },
    maxLength : function(v,elm,opt) {
        return v.length <= opt
    },
    min : function(v,elm,opt) {
        return v >= parseFloat(opt)
    },
    max : function(v,elm,opt) {
        return v <= parseFloat(opt)
    },
    notOneOf : function(v,elm,opt) {
        return $A(opt).all(function(value) {
            return v != value;
        })
    },
    oneOf : function(v,elm,opt) {
        return $A(opt).any(function(value) {
            return v == value;
        })
    },
    is : function(v,elm,opt) {
        return v == opt
    },
    isNot : function(v,elm,opt) {
        return v != opt
    },
    equalToField : function(v,elm,opt) {
        return v == $F(opt)
    },
    notEqualToField : function(v,elm,opt) {
        return v != $F(opt)
    },
    include : function(v,elm,opt) {
        return $A(opt).all(function(value) {
            return Validation.get(value).test(v,elm);
        })
    }
}

var Validation = Class.create();

Validation.prototype = {
    initialize : function(form, options){
        this.options = Object.extend({
            onSubmit : true,
            stopOnFirst : false,
            immediate : false,
            focusOnError : true,
            useTitles : false,
            onFormValidate : function(result, form) {},
            onElementValidate : function(result, elm) {}
        }, options || {});
        this.form = $(form);
        if(this.options.onSubmit) Event.observe(this.form,'submit',this.onSubmit.bind(this),false);
        if(this.options.immediate) {
            var useTitles = this.options.useTitles;
            var callback = this.options.onElementValidate;
            Form.getElements(this.form).each(function(input) { // Thanks Mike!
                Event.observe(input, 'blur', function(ev) {
                    Validation.validate(Event.element(ev),{
                        useTitle : useTitles,
                        onElementValidate : callback
                    });
                });
            });
        }
    },
    onSubmit :  function(ev){
        if(!this.validate() || validateTwiceKeyingForAllFields() == false || randomSamplingForTwiceKeyingFields() == false) {
            Event.stop(ev);
        } else {
            //used to uncheck the claim level eob
            var item = parent.$('claim_level_grid')
            if (item != null && item.checked){
                item.checked = false;
            }

            var agree;
            if($('submit_button_name') != null && ($F('submit_button_name') == 'SAVE EOB' ||
                $F('submit_button_name') == 'Save EOB' || $F('submit_button_name') == 'SAVE' ||
                $F('submit_button_name') == 'Save' || $F('submit_button_name') == 'Save Eob' ||
                $F('submit_button_name') == 'Update Job')){
                var validateForNextgen = true;
                if($F('submit_button_name') == 'Save Eob' && $('grid_type')) {
                    var gridTypeValue = $F('grid_type');
                    if(gridTypeValue == 'nextgen')
                        validateForNextgen = confirmNameAndIdentifier();
                }                
                if(validateForNextgen != true)
                    Event.stop(ev);
                else {
                    agree = confirm("Are You sure?");                
                    if (agree != true)
                        Event.stop(ev);
                    else{
                        bServicetimetracking  = true;
                        if($('submit_button_after_hiding') != null)
                            $('submit_button_after_hiding').value = $F('submit_button_name');
                        else if($('nextgen_proc_save_after_button_hiding') != null)
                            $('nextgen_proc_save_after_button_hiding').value = $F('submit_button_name');

                        if($('after_button_hiding') != null)
                            $('after_button_hiding').value = $F('submit_button_name');

                        if($('proc_save_eob_button_id') != null)
                            $('proc_save_eob_button_id').disabled = true;
                        else if($('qa_save_eob_button_id') != null)
                            $('qa_save_eob_button_id').disabled = true;

                        if($('qa_update_job_button_id') != null)
                            $('qa_update_job_button_id').disabled = true;
                        if($('qa_delete_eob_button_id') != null)
                            $('qa_delete_eob_button_id').disabled = true;
                    
                        if($('claim_level_service_lines_container') && claim_level_service_lines_window)
                            claim_level_service_lines_window.destroy();
                    }
                }

            }
        }
    },
    validate : function() {
        var result = false;
        var useTitles = this.options.useTitles;
        var callback = this.options.onElementValidate;
        if(this.options.stopOnFirst) {
            result = Form.getElements(this.form).all(function(elm) {
                return Validation.validate(elm,{
                    useTitle : useTitles,
                    onElementValidate : callback
                });
            });
        } else {
            result = Form.getElements(this.form).collect(function(elm) {
                return Validation.validate(elm,{
                    useTitle : useTitles,
                    onElementValidate : callback
                });
            }).all();
        }
        if(!result && this.options.focusOnError) {
            Form.getElements(this.form).findAll(function(elm){
                return $(elm).hasClassName('validation-failed')
            }).first().focus()
        }
        this.options.onFormValidate(result, this.form);
        return result;
    },
    reset : function() {
        Form.getElements(this.form).each(Validation.reset);
    }
}

Object.extend(Validation, {
    validate : function(elm, options){
        options = Object.extend({
            useTitle : false,
            onElementValidate : function(result, elm) {}
        }, options || {});
        elm = $(elm);
        var cn = elm.classNames();
        return result = cn.all(function(value) {
            var test = Validation.test(value,elm,options.useTitle);
            options.onElementValidate(test, elm);
            return test;
        });
    },
    test : function(name, elm, useTitle) {
        var v = Validation.get(name);
        var prop = '__advice'+name.camelize();
        try {
            if(Validation.isVisible(elm) && !v.test($F(elm), elm)) {
                if(!elm[prop]) {
                    var advice = Validation.getAdvice(name, elm);
                    if(advice == null) {
                        var errorMsg = useTitle ? ((elm && elm.title) ? elm.title : v.error) : v.error;
                        advice = '<div class="validation-advice" id="advice-' + name + '-' + Validation.getElmID(elm) +'" style="display:none">' + errorMsg + '</div>'
                        switch (elm.type.toLowerCase()) {
                            case 'checkbox':
                            case 'radio':
                                var p = elm.parentNode;
                                if(p) {
                                    new Insertion.Bottom(p, advice);
                                } else {
                                    new Insertion.After(elm, advice);
                                }
                                break;
                            default:
                                new Insertion.After(elm, advice);
                        }
                        advice = Validation.getAdvice(name, elm);
                    }
                    if(typeof Effect == 'undefined') {
                        advice.style.display = 'block';
                    } else {
                        elm.observe("focus", function(event){
                            new Effect.Appear(advice, {
                                duration : 0.5
                            });
                        });
                        elm.observe("blur", function(event){
                            new Effect.Fade(advice, {
                                duration : 0.5
                            });
                        });
                    }
                    advice.style.position = 'absolute';
                }
                elm[prop] = true;
                elm.removeClassName('validation-passed');
                elm.addClassName('validation-failed');
                return false;
            } else {
                var advice = Validation.getAdvice(name, elm);
                if(advice != null) advice.hide();
                elm[prop] = '';
                elm.removeClassName('validation-failed');
                elm.addClassName('validation-passed');
                return true;
            }
        } catch(e) {
            throw(e)
        }
    },
    isVisible : function(elm) {
        while(elm.tagName != 'BODY') {
            if(!$(elm).visible()) return false;
            elm = elm.parentNode;
        }
        return true;
    },
    getAdvice : function(name, elm) {
        return $('advice-' + name + '-' + Validation.getElmID(elm)) || $('advice-' + Validation.getElmID(elm));
    },
    getElmID : function(elm) {
        return elm.id ? elm.id : elm.name;
    },
    reset : function(elm) {
        elm = $(elm);
        var cn = elm.classNames();
        cn.each(function(value) {
            var prop = '__advice'+value.camelize();
            if(elm[prop]) {
                var advice = Validation.getAdvice(value, elm);
                advice.hide();
                elm[prop] = '';
            }
            elm.removeClassName('validation-failed');
            elm.removeClassName('validation-passed');
        });
    },
    add : function(className, error, test, options) {
        var nv = {};
        nv[className] = new Validator(className, error, test, options);
        Object.extend(Validation.methods, nv);
    },
    addAllThese : function(validators) {
        var nv = {};
        $A(validators).each(function(value) {
            nv[value[0]] = new Validator(value[0], value[1], value[2], (value.length > 3 ? value[3] : {}));
        });
        Object.extend(Validation.methods, nv);
    },
    get : function(name) {
        return  Validation.methods[name] ? Validation.methods[name] : Validation.methods['_LikeNoIDIEverSaw_'];
    },
    methods : {
        '_LikeNoIDIEverSaw_' : new Validator('_LikeNoIDIEverSaw_','',{})
    }
});

Validation.add('IsEmpty', '', function(v) {
    return  ((v == null) || (v.length == 0)); // || /^\s+$/.test(v));
});

Validation.addAllThese([

    ['required', 'Required field', function(v) {
        return !Validation.get('IsEmpty').test(v);
    }],
    ['validate-nonzero-checkamount', 'Required non zero value', function(value) {
        value = value.strip();
        if(value == '' || parseFloat(value) == 0){

            return false;
        }
        else
            return true;
    }],
    ['validate-check-date', 'Invalid date cannot be entered', function(value,element) {
        if($(element) != null && $(element).type != 'hidden') {
            value = value.strip();
            if(value == '' || value.toUpperCase() == "MM/DD/YY"){
                return false;
            }
            else{
                return true;
            }
        }
        else
            return true

    }],
    ['validate-cor-date', 'Date cannot be entered', function(value, element) {
        var result;
        if($(element) != null && $(element).type != 'hidden') {
            value = value.strip();
            if(value == '' || value.toUpperCase() == "MM/DD/YY"){
                result = true;
            }
            else{
                
                result = false;
            }
        }
        else{
            result = true;
        }
        return result;
    }],

    ['validate-tooth-number', 'Invalid Tooth Number', function(value, element) {
        var result = true;
        if($(element) != null && $(element).type != 'hidden' && value != '') {
            var tooth_code = value.toUpperCase();
            var tooth_number = tooth_code.split(',')
            var invalid_tooth_numbers = []
            if(!(tooth_code.match(/^[a-zA-Z0-9,]+$/))){
                result = false;
            }
            else if((tooth_number.indexOf("") == -1) == false){
                result = false;
            }
            else{
                for(var i = 0; i< tooth_number.length; i++){
                    if(((tooth_number[i].match(/^(?:[1-9]|1[0-9]|2[0-9]|3[0-2]?)$/)) == null) && ((tooth_number[i].match(/^[a-tA-T]$/)) == null) ){
                        invalid_tooth_numbers.push(tooth_number[i]);
                    }
                }
                if(invalid_tooth_numbers.length >  0){
                    result = false;
                }
            }

        }
        return result;
    }],

    ['validate-zero-check-amount', 'Required zero value', function(value) {
        value = value.strip();
        if(value == '' || parseFloat(value) == 0){
            return true;
        }
        else
            return false;
    }],
    ['validate-zero-number', 'Required zero value', function(value) {
        value = value.strip();
        if( value != '' && value.match(/^[0-9a-zA-Z]+$/ ) != null && value.match(/[^0]/) != null){
            return false;
        }
        else
            return true;
    }],
    ['validate-cpt_code_mandatory', 'Required 5 digit alphanumeric', function (v) {
        return (!Validation.get('IsEmpty').test(v) && /^[a-zA-Z0-9]+$/.test(v) && v.length == 5);
    }],
    ['validate-cpt_code_length', 'CPT code must be 5 digit alphanumeric', function (v) {
        var clientName = $F('client_name').strip().toUpperCase();
        var flag = true
        if(clientName != 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER'){
            flag = (Validation.get('IsEmpty').test(v) || (/^[a-zA-Z0-9]+$/.test(v) && v.length == 5));
        }
        return flag;       
    }],


    ['validate-upmc_revenue_code_cpt_code_length', 'Invalid CPT/Revenue Code Length', function (v) {
        var clientName = $F('client_name').strip().toUpperCase();
        var flag = true
        if(clientName == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER'){
            flag = (Validation.get('IsEmpty').test(v) || (/^[a-zA-Z0-9]+$/.test(v) && (v.length == 5 ||v.length == 4) ));
        }
        return flag;

    }],

    ['validate-modifier', 'Required 2 digit alphanumeric', function (v) {
        return (Validation.get('IsEmpty').test(v) || /^[a-zA-Z0-9]+$/.test(v) && v.length == 2);
    }],
    ['validate-bundled_cpt_code', 'Required 5 digit alphanumeric', function (v) {
        return (Validation.get('IsEmpty').test(v) || /^[a-zA-Z0-9]+$/.test(v) && v.length == 5);
    }],
    ['validate-payer_tin', 'Payer Tin must be 9 digit numeric', function (v) {
        return (Validation.get('IsEmpty').test(v) || /^[0-9]+$/.test(v) && v.length == 9);
    }],
    ['validate-carrier_code', 'Carrier Code length must be minimum of 2', function (v) {
        return (v.length != 1);
    }],
    ['validate-number', 'Required valid number', function(v) {
        return Validation.get('IsEmpty').test(v) || (!isNaN(v) && !/^\s+$/.test(v));
    }],
    ['validate-digits', 'Required number', function(v) {
        return Validation.get('IsEmpty').test(v) ||  (((v.match(/^[0-9]+(\.[0-9]+)?$/)) != null) ||  parseFloat(v) != '0');
    }],
    ['validate-alpha', 'Required letters only', function (v) {
        return Validation.get('IsEmpty').test(v) ||  (/^[a-zA-Z\s]+$/.test(v) && !/^\s+$/.test(v));
    }],
    ['validate-alpha-without-space', 'Required letters only', function (v) {
        return Validation.get('IsEmpty').test(v) ||  /^[a-zA-Z]+$/.test(v);
    }],
    ['validate-alphanumeric', 'Required alphanumeric only', function (v) {
        return Validation.get('IsEmpty').test(v) ||  /^[a-zA-Z0-9]+$/.test(v);
    }],
    ['validate-real_number', 'Required real numbers only', function (v) {
        return Validation.get('IsEmpty').test(v) ||  /^[0-9]+(\.[0-9]+)?$/.test(v);
    }],
    ['validate-capital', 'Required capital letters only', function (v) {
        return Validation.get('IsEmpty').test(v) ||  /^[A-Z]+$/.test(v);
    }],
    ['validate-3numeric', '3 digits only required', function (v) {
        return Validation.get('IsEmpty').test(v) ||  /(^\d{3}$)/.test(v);
    }],
    ['validate-2numeric', '2 digits only required', function (v) {
        return Validation.get('IsEmpty').test(v) || (!/(^0+$)/.test(v) && /(^\d{2}$)/.test(v));
    }],
    ['validate-3alpha', 'Required maximum of 3 digit alphanumeric', function (v) {
        return (Validation.get('IsEmpty').test(v) || /^[a-zA-Z0-9]+$/.test(v) && v.length <= 3);
    }],

    ['validate-20alpha', 'Required maximum of 20 digit alphanumeric', function (v) {
        return (Validation.get('IsEmpty').test(v) || /^[a-zA-Z0-9]+$/.test(v) && v.length <= 20);
    }],
    
    ['validate-non-blank-drop-down', 'Required Field', function (v) {
        document_classification_id = 'document_classification_id';
        if($(document_classification_id) != null && ($F(document_classification_id) == "" || $F(document_classification_id) == '--')){
            return Validation.get('IsEmpty').test(v);;
        }
        else{
            return true;
        }
    }],
    
    ['validate-balance', 'Balance Should be zero', function (v,elem) {
        if($(elem.id).value == '0.00' || $(elem.id).value == '0.0'){
            return true;
        }
        else  if($(elem.id).value == '-0.00'){
            return true;
        }
        else if($(elem.id).value == '+0.00'){
            return true;
        }
        else if($F(elem.id).blank()) {
            return !elem.value.blank();
        }
        else{
            return Validation.get('IsEmpty').test(v);
        }
    }],

    // Charge must be non-zero validation for BAC client 'MDR - Marina Del Ray' (MDR) with sitecode 00P84
    
    ['validate-charge_in_service', 'Charge must be non-zero. If charge is not specified, capture payment amount as Charge', function (v,elem) {
        var svc_line_count = elem.id.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "")
        if(svc_line_count != "" && svc_line_count != null){
            charge_field_id = 'service_procedure_charge_amount_id' + svc_line_count;
            payment_field_id = 'service_paid_amount_id' + svc_line_count;
        }
        if(($F(payment_field_id) != "" && parseFloat($F(payment_field_id)) != "0.00") && (parseFloat($F(charge_field_id)) == '0.00' || $F(charge_field_id) == '')){
            return Validation.get('IsEmpty').test(v);;
        }
        else{
            return true;
        }
    }],
    
    // Charge must be non-zero validation for BAC client - in claim level EOB for
    //'MDR - Marina Del Ray' (MDR) with sitecode 00P84
    
    ['validate-charge_in_claim_level_eob', 'Charge must be non-zero. If charge is not specified, capture payment amount as Charge', function (v,elem) {
        charge_field_id = 'total_charge_id';
        payment_field_id = 'total_payment_id';
        if(($F(payment_field_id) != "" && parseFloat($F(payment_field_id)) != "0.00") && (parseFloat($F(charge_field_id)) == '0.00' || $F(charge_field_id) == '')){
            return Validation.get('IsEmpty').test(v);;
        }
        else{
            return true;
        }
    }],
        
    ['validate-claimreasoncode', 'claimreasoncode', function (v,elem) {
        if ($F('count') == 0 && ($F('mpi_identification')==0 || $F('mpi_identification')==-1 )) {
            var code = elem.id.split("_")
            if (code[2] == 'noncovered') {
                if ($F('total_non_covered_id').blank() || ($F('total_non_covered_id') == 0)) {
                    return true;
                }
                else {
                    return !elem.value.blank();
                }
            }
            else
            if (code[2] == 'discount') {
                if ($F('total_discount_id').blank() || ($F('total_discount_id') == 0)) {
                    return true;
                }
                else {
                    return !elem.value.blank();
                }
            }
            else
            if (code[2] == 'coinsurance') {
                if ($F('total_coinsurance_id').blank() || ($F('total_coinsurance_id') == 0)) {
                    return true;
                }
                else {
                    return !elem.value.blank();
                }
            }
            else
            if (code[2] == 'deductable') {
                if ($F('total_deductable_id').blank() || ($F('total_deductable_id') == 0)) {
                    return true;
                }
                else {
                    return !elem.value.blank();
                }
            }
            else
            if (code[2] == 'deductable') {
                if ($F('total_deductable_id').blank() || ($F('total_deductable_id') == 0)) {
                    return true;
                }
                else {
                    return !elem.value.blank();
                }
            }
            else
            if (code[2] == 'copay') {
                if ($F('total_copay_id').blank() || ($F('total_copay_id') == 0)) {
                    return true;
                }
                else {
                    return !elem.value.blank();
                }
            }
            else
            if (code[2] == 'primary') {
                if ($F('total_primary_payment_id').blank() || ($F('total_primary_payment_id') == 0)) {
                    return true;
                }
                else {
                    return !elem.value.blank();
                }
            }
            else
            if (code[2] == 'contractual') {
                if ($F('total_contractual_amount_id').blank() || ($F('total_contractual_amount_id') == 0)) {
                    return true;
                }
                else {
                    return !elem.value.blank();
                }
            }
            else
            if (code[2] == 'denied' && $F('denied_status') == "true") {
                if ($F('total_denied_id').blank() || ($F('total_denied_id') == 0)) {
                    return true;
                }
                else {
                    return !elem.value.blank();
                }
            }

            else {
                return true;
            }
        }
        else{
            return true;
        }
					
    }],

    ['validate-date_range', 'From date should be less than or equal to To date',
    function(v, elem) {
        if(compareDates(elem.id) == false){
            return Validation.get('IsEmpty').test(v);
        }
        else{
            return true;
        }
    }],

    ['validate-unique-code', 'Enter Valid Unique Code', function(v, elem) {
        if (!elem.value.blank()) {
            return isUniqueCodeValid(elem.id);
        }
        else
            return true;
    }],
    ['validate-alphanum', 'Required letters or numbers only', function(v) {
        return Validation.get('IsEmpty').test(v) ||  !/\W/.test(v)
    }],
    ['validate-alphahyphen', 'Required letters or hyphen only', function(v) {
        return Validation.get('IsEmpty').test(v) ||  /^[A-Za-z\-]*$/.test(v)
    }],
    ['validate-patient_account_number', 'Required alphanumeric, hyphen or period only', function(v) {
        return Validation.get('IsEmpty').test(v) || (/^[A-Za-z0-9\-\.]*$/.test(v) && !/\.{2}|\-{2}|^[\-\.]+$/.test(v))
    }],
    ['validate-percentage_data', 'Required Valid Plan Coverage', function(v, element) {

        var return_result =  Validation.get('IsEmpty').test(v) || (/^0*(?:[0-9]{1,2}|100)$/.test(v))
        if(return_result == true && $F(element.id) != '' && $(element.id) != null){
            $(element.id).value = parseFloat($F(element.id));
        }
        return return_result;
    }],
    ['validate-alphanum-hyphen-space-period', 'Required alphanumeric, hyphen, space or period only', function(v) {
        return Validation.get('IsEmpty').test(v) || (/^[A-Za-z0-9\-\s\.]*$/.test(v) && !/\.{2}|\-{2}|\s{2}|^[\-\.\s]+$/.test(v))
    }],
    ['validate-date', 'Required valid date', function(v, element){
        var RegDatePattern = /^(?=\d)(?:(?:(?:(?:(?:0?[13578]|1[02])(\/|-|\.)31)\1|(?:(?:0?[1,3-9]|1[0-2])(\/|-|\.)(?:29|30)\2))(?:(?:1[6-9]|[2-9]\d)?\d{2})|(?:0?2(\/|-|\.)29\3(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))|(?:(?:0?[1-9])|(?:1[0-2]))(\/|-|\.)(?:0?[1-9]|1\d|2[0-8])\4(?:(?:1[6-9]|[2-9]\d)?\d{2}))($|\ (?=\d)))?(((0?[1-9]|1[012])(:[0-5]\d){0,2}(\ [AP]M))|([01]\d|2[0-3])(:[0-5]\d){1,2})?$/;
        if (Validation.get('IsEmpty').test(v))
            return true
        else if (RegDatePattern.test(v)){ //check for future date
            var dateSeparator = v.substring(2, 3);
            var arrayDate = v.split(dateSeparator);
            var month = arrayDate[0];
            var day = arrayDate[1];
            var year = arrayDate[2];
            var centuryNumber = getCentury(v);
            year = centuryNumber + year;
            var myDate = new Date();
            myDate.setFullYear(year, parseInt(month) - 1, day);
            var today = new Date();
            var valid = true;
            if (myDate > today) {
                if(element.id == 'checkdate_id') {
                    valid = true;
                }
                else
                    valid = false;
            }
            return valid
        }
        else
            return false
    }],
    ['validate-payer_state', 'Payer State must be 2 alphabets', function(v) {
        return (Validation.get('IsEmpty').test(v) || /^[a-zA-Z]+$/.test(v) && v.length == 2);
    }],
    ['validate-date-comparision', 'The From Date should be less than To Date. Please correct the date and try again.', function(v, elem){
        var fieldId = elem.id;
        var fromDateId;
        var toDateId;
        if(fieldId.search(/from/) != -1) {
            fromDateId = fieldId;
            toDateId = fieldId.replace('from', 'to');
        }
        else if(fieldId.search(/to/) != -1) {
            toDateId = fieldId;
            fromDateId = fieldId.replace('to', 'from');
        }

        validateFromToDate = validateDateRange(fromDateId, toDateId)
        // Compares if 'From date' is < 'to date'.
        function validateDateRange(fromDateId, toDateId){
            var validation = true;
            if($(fromDateId) != null && $(toDateId) != null && validateDate(fromDateId)) {
                if($F(fromDateId) != "" && $F(toDateId) != "" ) {
                    validation = false;
                    var arrayFromDate = $F(fromDateId).split("/");
                    var arrayToDate = $F(toDateId).split("/");
                    if(arrayFromDate[2] == arrayToDate[2]) {
                        if(arrayFromDate[0] == arrayToDate[0]) {
                            if(arrayFromDate[1] == arrayToDate[1])
                                validation = true;
                            else if(arrayFromDate[1] < arrayToDate[1])
                                validation = true;
                        }
                        else if(arrayFromDate[0] < arrayToDate[0])
                            validation = true;
                    }
                    else if(arrayFromDate[2] < arrayToDate[2]){
                        validation = true;
                    }
                }
            }
            if(!validation) {
                return false;
            }
            return validation;
        }
        if (validateFromToDate == false)
            return false;
        else
            return true;

    }],
    ['validate-accountnumber', ' Account number Not Valid ', function(v,elem) {
        accountNumber = $('patient_account_id').value
        validateAccountNumer = validateAccountNumber(accountNumber)
        if(validateAccountNumer == 'Found'){
            return Validation.get('IsEmpty').test(v)
        }
        else{
            return true;
        }
        function validateAccountNumber(accountNumber)
        {            
            type = null;
            if($('facility') != null){
                if ($F('facility').toUpperCase() == 'RICHMOND UNIVERSITY MEDICAL CENTER'){
                    var accountNumerExceptionArray = ["J01","J03"];
                    for (var i = 0; i < accountNumerExceptionArray.length; i++) {
                        if (accountNumber.match(accountNumerExceptionArray[i])) {
                            type = "Found";
                            break;
                        }
                    }
                }
            }
            return type;
        }
    }],

    ['validate-qudax-account-number', 'Patient Account Number should start with the Client Code', function(v,elem) {
        accountNumber = elem.value.toUpperCase();
        var clientCode = $F('sitecode').toUpperCase();
        var checkPrefix  = $F('details_account_num_prefix');
        var validateAccountNumer = validateAccountNumber(accountNumber, clientCode,checkPrefix);
        if(validateAccountNumer == 'Not Found'){
            alert('Patient Account Number should start with the Client Code : ' + clientCode);
            return false;
        }
        else{
            return true;
        }
        function validateAccountNumber(accountNumber, clientCode,checkPrefix)
        {
            type = null;
            if (checkPrefix == 'true' && clientCode != ""){
                if (accountNumber != "" && accountNumber.startsWith(clientCode) == false){
                    type = "Not Found";
                    setTimeout(function() {
                        document.getElementById(accNumId).focus();
                    }, 10);
                }
            }
            return type;
        }
    }],
    ['validate-rumc_accountnumber', 'Required alphanumeric', function (v) {
        rumcaccountnumber = $('patient_account_id').value
        if($('facility') != null){
            rumc_payee = $F('facility').toUpperCase();
            if (rumc_payee == 'RICHMOND UNIVERSITY MEDICAL CENTER'){
                if (/^[a-zA-Z0-9]+$/.test(v)){
                    return true;
                }
                else{
                    alert("Account number must be alphanumeric!");
                    return false;   
                }
            }
            else
                return true;
        }
        else
            return true;
    }],
    ['validate-moxp-account-number', 'Invalid Account Number', function (v) {
        if($('facility') != null){
            var moxpPayee = $F('facility').toUpperCase();
            if (moxpPayee == 'MOUNT NITTANY MEDICAL CENTER'){
                if ((/^[A-Z]{3}([0-9]){5}$/).test(v) || (/^[A-LN-Z]([0-9]){11}$/).test(v) || (/^[M]{1}[0-9]+$/).test(v) || (v == "MOXP0")){
                    return true;
                }
                else{
                    return false;
                }
            }
            else
                return true;
        }
        else
            return true;
    }],
    ['validate-email', 'Required valid email', function (v) {
        return Validation.get('IsEmpty').test(v) || /\w{1,}[@][\w\-]{1,}([.]([\w\-]{1,})){1,3}$/.test(v)
    }],
    ['validate-url', 'Required valid url', function (v) {
        return Validation.get('IsEmpty').test(v) || /^(http|https|ftp):\/\/(([A-Z0-9][A-Z0-9_-]*)(\.[A-Z0-9][A-Z0-9_-]*)+)(:(\d+))?\/?/i.test(v)
    }],
    ['validate-zipcode', 'Required valid zipcode', function (v) {
        return Validation.get('IsEmpty').test(v) || /(^\d{5}$)|(^\d{9}$)/.test(v)
    }],
    ['validate-revenue-code', 'Required valid Revenue Code', function (v) {
        return Validation.get('IsEmpty').test(v) || /(^\d{4}$)/.test(v)
    }],
    ['validate-npi', 'Required valid NPI', function (v) {
        return Validation.get('IsEmpty').test(v) || /(^\d{10}$)/.test(v)
    }],
    ['validate-tin', 'Required valid TIN', function (v) {
        return Validation.get('IsEmpty').test(v) || /(^\d{9}$)/.test(v)
    }],
    ['validate-date-au', 'Required valid date format', function(v) {
        if(Validation.get('IsEmpty').test(v)) return true;
        var regex = /^(\d{2})\/(\d{2})\/(\d{4})$/;
        if(!regex.test(v)) return false;
        var d = new Date(v.replace(regex, '$2/$1/$3'));
        return ( parseInt(RegExp.$2, 10) == (1+d.getMonth()) ) &&
        (parseInt(RegExp.$1, 10) == d.getDate()) &&
        (parseInt(RegExp.$3, 10) == d.getFullYear() );
    }],
    ['validate-date-us', ' Required valid date format', function (v) {
        var RegDatePattern = /^(?=\d)(?:(?:(?:(?:(?:0?[13578]|1[02])(\/|-|\.)31)\1|(?:(?:0?[1,3-9]|1[0-2])(\/|-|\.)(?:29|30)\2))(?:(?:1[6-9]|[2-9]\d)?\d{2})|(?:0?2(\/|-|\.)29\3(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))|(?:(?:0?[1-9])|(?:1[0-2]))(\/|-|\.)(?:0?[1-9]|1\d|2[0-8])\4(?:(?:1[6-9]|[2-9]\d)?\d{2}))($|\ (?=\d)))?(((0?[1-9]|1[012])(:[0-5]\d){0,2}(\ [AP]M))|([01]\d|2[0-3])(:[0-5]\d){1,2})?$/;
        return Validation.get('IsEmpty').test(v) || RegDatePattern.test(v)
    }],
    ['validate-currency-dollar', 'Required valid $ amount,can have upto 2 decimal places', function(v) {
        // [$]1[##][,###]+[.##]
        // [$]1###+[.##]
        // [$]0.##
        // [$].##
        return Validation.get('IsEmpty').test(v) ||  /^\$?\-?([1-9]{1}[0-9]{0,2}(\,[0-9]{3})*(\.[0-9]{0,2})?|[1-9]{1}\d*(\.[0-9]{0,2})?|0(\.[0-9]{0,2})?|(\.[0-9]{1,2})?)$/.test(v)
    }],
    ['validate-selection', 'Required selection', function(v,elm){
        return elm.options ? elm.selectedIndex > 0 : !Validation.get('IsEmpty').test(v);
    }],
    ['validate-one-required', 'Required atleast one', function (v,elm) {
        var p = elm.parentNode;
        var options = p.getElementsByTagName('INPUT');
        return $A(options).any(function(elm) {
            return $F(elm);
        });
    }],
    ['validate-nonzero-alphanum', 'Required nonzero numbers or letters', function(v) {
        return Validation.get('IsEmpty').test(v) || (/^[0-9a-zA-Z]+$/.test(v)) && (/[^0]/.test(v))
    }],
    ['validate-aba', 'Required 9 digit nonzero numbers only', function(v) {
        return (Validation.get('IsEmpty').test(v) || /^[0-9]+$/.test(v) && /[^0]/.test(v) && /(^\d{9}$)/.test(v))
    }],
    ['validate-payer-acc-num', 'Required 3-15 digit nonzero numbers only', function(v) {
        return (Validation.get('IsEmpty').test(v) || /^[0-9]+$/.test(v) && /[^0]/.test(v) && v.length >= 3 && v.length <= 15)
    }],
    ['set-default-value-from-fc', 'No default value', function (v,elm) {
        var claimLevelEob = ((parent.document.getElementById('claim_level_grid') != null && parent.document.getElementById('claim_level_grid').checked == true) || ($('claim_level_eob') != null && $F('claim_level_eob') == "true"));
        var isPopulateDefaultValues = '';
        if($('populate_default_values') != null)
            isPopulateDefaultValues = $F('populate_default_values');
        var elementId = elm.id;               
        var date = $F('fc_def_sdate');
        if(date.strip().length == 10) {
            var dateArray = date.split('/');
            var year = dateArray[2].slice(2); // extracting last two digits of year
            var defaultDate = dateArray[0] + '/' + dateArray[1] + '/' + year; // combining into date
        }
        else {
            defaultDate = date;
        }
        var insurancePay = $F('insurance_grid');
        var defaultDateChoice = $F('fc_def_sdate_choice');
        var keyInCheckDate;
        var balance;
        var charge = $F(elementId);
        if($('checkdate_id') != null)
            keyInCheckDate = $F('checkdate_id');
        else
            keyInCheckDate = ''
        if(isPopulateDefaultValues == "1" && insurancePay != "true"){
            if((elementId.match("date_service") != null || (claimLevelEob && (elementId.match("claim_from_date") != null || elementId.match("claim_to_date") != null))) && ($F(elementId) == "" || $F(elementId) == "mm/dd/yy")){
                if(defaultDateChoice == "Check Date"){
                    $(elementId).value = keyInCheckDate;
                    return true;
                }
                else{
                    if(defaultDate != null && defaultDate != "mm/dd/yy"){
                        $(elementId).value = defaultDate;
                        return true;
                    }
                    else
                        return false;
                }
            }
            else if(!claimLevelEob && elementId.match("procedure_code") != null && $F(elementId) == ""){
                var defaultProcedureCode = $F('fc_def_cpt_code');
                if(defaultProcedureCode != null){
                    $(elementId).value = defaultProcedureCode;
                    return true;
                }
                else{
                    return false;
                }
            }
            else if(claimLevelEob && elementId.match("total_charge") != null){
                var totalPayment = $F('total_payment_id');
                var totalServiceBalance = $F('total_service_balance_id');
                var totalCopay = $F('total_copay_id');
                var totalContarctualAllowance = $F('total_contractual_amount_id');
                if(totalPayment != null && totalPayment != ""){
                    totalPayment = parseFloat(totalPayment);
                    if(charge == "")
                        charge = 0.00;
                    balance = parseFloat(charge) - totalPayment;
                    if(parseFloat(totalServiceBalance) == balance){
                        $('total_service_balance_id').value = "0.00";
                    }
                    else if(totalCopay != "" && totalContarctualAllowance != ""){
                        $('total_service_balance_id').value = -(parseFloat(totalCopay)+parseFloat(totalContarctualAllowance));

                    }
                    else if (totalCopay != ""){
                        $('total_service_balance_id').value = -parseFloat(totalCopay);
                    }
                    else if (totalContarctualAllowance != ""){
                        $('total_service_balance_id').value = -parseFloat(totalContarctualAllowance);
                    }

                    $(elementId).value = totalPayment;
                    return true;
                }
                else{
                    return false;
                }
            }
            else if(!claimLevelEob && elementId.match("service_procedure_charge") != null){
                var totalSvcBalance = 0.00;
                var svcLineSerialNo = elementId.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "")
                var payment = $F('service_paid_amount_id'+ svcLineSerialNo);
                var serviceBalance = $F('service_balance_id' + svcLineSerialNo);
                var copay = $F('service_co_pay_id' +svcLineSerialNo);
                var contarctualAllowance = $F('service_contractual_amount_id'+svcLineSerialNo);
                if(payment != null && payment != ""){
                    payment = parseFloat(payment);
                    if(charge == "")
                        charge = 0.00;
                    balance = parseFloat(charge) - payment;
                    if(parseFloat(serviceBalance) == balance){
                        $('service_balance_id' + svcLineSerialNo).value = "0.00";
                    }
                    else if(copay != "" && contarctualAllowance != ""){
                        $('service_balance_id' + svcLineSerialNo).value = -(parseFloat(copay)+parseFloat(contarctualAllowance));

                    }
                    else if (copay != ""){
                        $('service_balance_id' + svcLineSerialNo).value = -parseFloat(copay);
                    }
                    else if (contarctualAllowance != ""){
                        $('service_balance_id' + svcLineSerialNo).value = -parseFloat(contarctualAllowance);
                    }

                    for(j = 1; j <= svcLineSerialNo; j++){
                        totalSvcBalance += parseFloat($F('service_balance_id' + j));
                    }

                    if (totalSvcBalance == 0)
                        $('total_service_balance_id').value = "0.00";
                    else
                        $('total_service_balance_id').value = totalSvcBalance;

                    $(elementId).value = payment;
                    $('total_charge_id').value = $F('total_payment_id');
                    return true;
                }
                else{
                    return false;
                }
            }
            else{
                return true;
            }
        }
        else {
            
            return true;
        }
    }],

    ['validate-quantity', 'Required valid quantity', function (value) {
        return Validation.get('IsEmpty').test(value) ||  /^[\-\d]{0,3}[\.\d]{0,3}$/.test(value);
    }],

    ['validate-alphanumeric-hyphen-period-forwardslash', 'Required alphanumeric, hyphen, period or forward slash only', function(v) {       
        return Validation.get('IsEmpty').test(v) || /^[A-Za-z0-9\-\.\/]*$/.test(v);
    }],
    ['validate-limit-of-special-characters', 'Not allowed more than two hyphens or periods or forward slashes!', function(v) {
        var temp = 'a'+v+'a';
        var arrayOfstringWithoutForwardSlash = temp.split(/\//);
        var arrayOfstringWithoutPeriods = temp.split(/\./);
        var arrayOfstringWithoutHyphen = temp.split(/\-/);
        return Validation.get('IsEmpty').test(v) ||
        (!(arrayOfstringWithoutForwardSlash.length > 3) && !(arrayOfstringWithoutPeriods.length > 3) && !(arrayOfstringWithoutHyphen.length > 3));
    }],
    ['validate-conecutive-special-characters-for-patient-account-number-nonbank', 'Not allowed consecutive special characters', function(v) {
        var invalidAccNo = /^((\.\/\-|\-\/\.|\.\-\/|\-\.\/|\/\.\-|\/\-\.|\-\.|\.\-|\-\/|\/\-|\/\.|\.\/)[A-Za-z0-9\-\.\/]*)|([A-Za-z0-9\-\.\/]*(\.\/\-|\-\/\.|\.\-\/|\-\.\/|\/\.\-|\/\-\.|\-\.|\.\-|\-\/|\/\-|\/\.|\.\/))|([A-Za-z0-9\-\.\/]*(\.\/\-|\-\/\.|\.\-\/|\-\.\/|\/\.\-|\/\-\.|\-\.|\.\-|\-\/|\/\-|\/\.|\.\/)[A-Za-z0-9\-\.\/]*)$/
        return Validation.get('IsEmpty').test(v) || (!invalidAccNo.test(v) && !/\.{2}|\-{2}|\/{2}|^[\-\.\/]+$/.test(v));
    }],

    ['validate-length-12-for-nextgen-account-number', 'Account# should be less than or equal to 12 digits', function(value) {
        return (value.length != 0 && value.length <= 12);
    }],

    ['validate-length-16-for-nextgen-account-number', 'Account# should be 16 digits', function(value) {
        return (value.length != 0 && value.length == 16);
    }],

    ['validate-cpt-or-revenue-code-mandatory', 'Required CPT or Revenue Code', function (value, element) {
        var svcLineSerialNo = element.id.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
        var procedureCodeId = 'procedure_code_' + svcLineSerialNo;
        var revenueCodeId = 'revenue_code_' + svcLineSerialNo;
        return (procedureCodeOrRevenueCodeMandatory(procedureCodeId, revenueCodeId, svcLineSerialNo) );
    }]

    ]);
