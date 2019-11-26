import { connect, MapStateToProps } from 'react-redux';

import { App, AppStateProps } from './app.component';
import { selectReady } from './concerns/control/control.selectors';
import { AppState } from './store/state';

const mapStateToProps: MapStateToProps<AppStateProps, {}, AppState> = state => ({
  ready: selectReady(state)
});

const mapDispatchToProps = () => ({});

export const AppContainer = connect(mapStateToProps, mapDispatchToProps)(App);