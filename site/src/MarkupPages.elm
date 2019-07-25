module MarkupPages exposing (Flags, Parser, Program, program)

import Browser
import Browser.Navigation
import Content exposing (Content)
import Dict exposing (Dict)
import Element exposing (Element)
import Json.Decode
import Mark
import MarkParser
import Platform.Sub exposing (Sub)
import Url exposing (Url)


type alias PageOrPost msg =
    { body : List (Element msg)
    , metadata : Metadata msg
    }


type alias Metadata msg =
    { description : String
    , title : { styled : Element msg, raw : String }
    }


type alias Content =
    { posts :
        List ( List String, String )
    , pages :
        List ( List String, String )
    }


type alias Program userFlags userModel userMsg =
    Platform.Program (Flags userFlags) (Model userModel) (Msg userMsg)


mainView :
    Content
    -> Parser userMsg
    -> (userModel -> MarkParser.PageOrPost userMsg -> { title : String, body : Element userMsg })
    -> Model userModel
    -> { title : String, body : Element userMsg }
mainView content parser pageOrPostView (Model model) =
    case Content.buildAllData parser model.imageAssets content of
        Ok site ->
            pageView parser pageOrPostView (Model model) site

        Err errorView ->
            { title = "Error parsing"
            , body = errorView
            }


pageView :
    Parser userMsg
    -> (userModel -> MarkParser.PageOrPost userMsg -> { title : String, body : Element userMsg })
    -> Model userModel
    -> Content.Content userMsg
    -> { title : String, body : Element userMsg }
pageView parser pageOrPostView (Model model) content =
    case Content.lookup content model.url of
        Just pageOrPost ->
            pageOrPostView model.userModel pageOrPost

        Nothing ->
            { title = "Page not found"
            , body =
                Element.column []
                    [ Element.text "Page not found. Valid routes:\n\n"
                    , (content.pages ++ content.posts)
                        |> List.map Tuple.first
                        |> List.map (String.join "/")
                        |> String.join ", "
                        |> Element.text
                    ]
            }


view :
    Content
    -> Parser userMsg
    -> (userModel -> MarkParser.PageOrPost userMsg -> { title : String, body : Element userMsg })
    -> Model userModel
    -> Browser.Document (Msg userMsg)
view content parser pageOrPostView model =
    let
        { title, body } =
            mainView content parser pageOrPostView model
    in
    { title = title
    , body =
        [ body
            |> Element.map UserMsg
            |> Element.layout
                [ Element.width Element.fill
                ]
        ]
    }


type alias Flags userFlags =
    { userFlags
        | imageAssets : Json.Decode.Value
    }


init :
    (Flags userFlags -> ( userModel, Cmd userMsg ))
    -> Flags userFlags
    -> Url
    -> Browser.Navigation.Key
    -> ( Model userModel, Cmd (Msg userMsg) )
init initUserModel flags url key =
    let
        ( userModel, userCmd ) =
            initUserModel flags
    in
    ( Model
        { key = key
        , url = url
        , imageAssets =
            Json.Decode.decodeValue
                (Json.Decode.dict Json.Decode.string)
                flags.imageAssets
                |> Result.withDefault Dict.empty
        , userModel = userModel
        }
    , userCmd |> Cmd.map UserMsg
    )


type Msg userMsg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | UserMsg userMsg


type Model userModel
    = Model
        { key : Browser.Navigation.Key
        , url : Url.Url
        , imageAssets : Dict String String
        , userModel : userModel
        }


update :
    (userMsg -> userModel -> ( userModel, Cmd userMsg ))
    -> Msg userMsg
    -> Model userModel
    -> ( Model userModel, Cmd (Msg userMsg) )
update userUpdate msg (Model model) =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( Model model, Browser.Navigation.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( Model model, Browser.Navigation.load href )

        UrlChanged url ->
            ( Model { model | url = url }
            , Cmd.none
            )

        UserMsg userMsg ->
            let
                ( userModel, userCmd ) =
                    userUpdate userMsg model.userModel
            in
            ( Model { model | userModel = userModel }, userCmd |> Cmd.map UserMsg )


type alias Parser userMsg =
    Dict String String
    -> List String
    -> Element userMsg
    -> Mark.Document { body : List (Element userMsg), metadata : MarkParser.Metadata userMsg }


program :
    { init : Flags userFlags -> ( userModel, Cmd userMsg )
    , update : userMsg -> userModel -> ( userModel, Cmd userMsg )
    , subscriptions : userModel -> Sub userMsg
    , view : userModel -> MarkParser.PageOrPost userMsg -> { title : String, body : Element userMsg }
    , parser : Parser userMsg
    , content : Content
    }
    -> Program userFlags userModel userMsg
program config =
    Browser.application
        { init = init config.init
        , view = view config.content config.parser config.view
        , update = update config.update
        , subscriptions = \_ -> Sub.none --config.subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
