import { ChangeEvent, ElementType, FormEvent } from 'react';
import { FormControlProps } from 'react-bootstrap';
import { BsPrefixProps, ReplaceProps } from 'react-bootstrap/helpers';

export type FormCheckboxChangeEvent = ChangeEvent<HTMLInputElement>;
export type FormInputChangeEvent = FormEvent<ReplaceProps<'input', BsPrefixProps<'input'> & FormControlProps>>;
export type FormSelectChangeEvent = FormEvent<ReplaceProps<ElementType, BsPrefixProps<ElementType> & FormControlProps>>;
export type FormSubmitEvent = FormEvent<HTMLFormElement>;

export interface FormFieldValidations {
  readonly [key: string]: any;
}

export interface FormValidations {
  readonly [key: string]: FormFieldValidations;
}

export function isFieldInvalid<T extends FormFieldValidations>(validations: T) {
  for (const key in validations) {
    const value = validations[key];
    if (value !== undefined && value !== null && value !== false) {
      return true;
    }
  }

  return false;
}

export function isFormInvalid<T extends FormValidations>(validations: T) {
  for (const key in validations) {
    if (isFieldInvalid(validations[key])) {
      return true;
    }
  }

  return false;
}

export function preventDefault<E extends Event | FormEvent>(handler: (event: E) => void) {
  return (event: E) => {
    event.preventDefault();
    handler(event);
  };
}