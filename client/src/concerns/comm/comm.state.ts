import { Action } from 'typescript-fsa';

export type CommunicationState = Array<Action<any>>;

export const initialCommunicationState: CommunicationState = [];