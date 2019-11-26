import { createSelector } from 'reselect';

import { selectControlState } from '../../store/selectors';

export const selectReady = createSelector(
  selectControlState,
  control => control.ready
);