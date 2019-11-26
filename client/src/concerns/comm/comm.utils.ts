import { isEqual } from 'lodash';
import { createSelector } from 'reselect';
import { Action, ActionCreator, AsyncActionCreators } from 'typescript-fsa';

import { selectCommunicationState } from '../../store/selectors';

export function createCommunicationActionInProgressSelector(creator: AsyncActionCreators<any, any, any>) {
  return createSelector(
    createCommunicationActionSelector(creator),
    action => action !== undefined
  );
}

export function createCommunicationActionSelector<T extends AsyncActionCreators<any, any, any>>(creator: T) {
  return createSelector(
    selectCommunicationState,
    comm => comm.find(creator.started.match)
  );
}

export function completionActionHasSameParams(
  ongoingAction: Action<any>,
  completionAction: Action<any>
) {
  const completionPayload = completionAction.payload;
  return payloadHasParams(completionPayload) && isEqual(ongoingAction.payload, completionPayload.params);
}

export function getCompletionCreators(actionCreators: Array<AsyncActionCreators<any, any, any>>) {
  const creators: Array<ActionCreator<any>> = [];
  return actionCreators.reduce(
    (memo, actionCreator) => [
      ...memo,
      actionCreator.done,
      actionCreator.failed
    ],
    creators
  );
}

export function isCompletionAction(startAction: Action<any>, completionAction: Action<any>) {
  return startAction.type.match(/^.+_STARTED$/) !== null
    && (
      (completionAction.type.match(/^.+_FAILED$/) !== null && startAction.type.slice(0, -8) === completionAction.type.slice(0, -7))
      || (completionAction.type.match(/^.+_DONE$/) !== null && startAction.type.slice(0, -8) === completionAction.type.slice(0, -5))
    );
}

function payloadHasParams(payload: unknown): payload is { params: unknown } {
  return payload !== null && typeof payload === 'object';
}