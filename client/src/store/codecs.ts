import * as t from 'io-ts';

import { SessionStateCodec } from '../concerns/session/session.codecs';

export const SavedStateCodec = t.interface({
  session: SessionStateCodec
});