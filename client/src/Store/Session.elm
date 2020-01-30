module Store.Session exposing (AuthModel, SessionModel, sessionDecoder, sessionEncoder)

import Api.Model exposing (ApiUser, apiUserDecoder, apiUserEncoder)
import Json.Decode as Decode exposing (field, map2, maybe, string)
import Json.Encode as Encode


type alias AuthModel =
    { token : String
    , user : ApiUser
    }


type alias SessionModel =
    Maybe AuthModel


encodeAuthModel : AuthModel -> Encode.Value
encodeAuthModel auth =
    Encode.object
        [ ( "token", Encode.string auth.token )
        , ( "user", apiUserEncoder auth.user )]


sessionDecoder : Decode.Decoder SessionModel
sessionDecoder =
    maybe (map2 AuthModel (field "token" string) (field "user" apiUserDecoder))


sessionEncoder : SessionModel -> Encode.Value
sessionEncoder model =
    Maybe.withDefault Encode.null (Maybe.map encodeAuthModel model)
