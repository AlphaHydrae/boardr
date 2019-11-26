import { isRight } from 'fp-ts/lib/Either';
import * as t from 'io-ts';

export function decode<C extends t.TypeC<any>>(codec: C, value: unknown): t.TypeOf<C> | undefined {
  const decoded = codec.decode(value);
  return isRight(decoded) ? decoded.right : undefined;
}