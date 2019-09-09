port module Main exposing (main)

import Animation
import Browser
import Browser.Dom as Dom
import Browser.Events
import Browser.Navigation as Nav
import Color
import Dict exposing (Dict)
import Dimensions exposing (Dimensions)
import Ease
import Element exposing (Element)
import Element.Border
import Element.Font as Font
import ElmLogo
import Head as Head exposing (Tag)
import Head.Seo
import Html exposing (Html)
import Html.Attributes
import Json.Decode
import Json.Encode
import List.Extra
import Mark
import Mark.Error
import MarkParser
import Metadata exposing (Metadata)
import Pages exposing (Page)
import Pages.Document
import Pages.Manifest as Manifest
import Pages.Manifest.Category
import PagesNew exposing (images, pages)
import RawContent
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Task
import Time
import Url exposing (Url)
import Url.Builder
import View.MenuBar
import View.Navbar


main : Pages.Program Model Msg (Metadata Msg) (List (Element Msg))
main =
    PagesNew.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , documents = [ markupDocument ]
        , head = head
        , manifest = manifest
        , canonicalSiteUrl = "https://incrementalelm.com"
        }


markupDocument : Pages.Document.DocumentParser (Metadata Msg) (List (Element Msg))
markupDocument =
    Pages.Document.markupParser
        (Metadata.metadata Dict.empty |> Mark.document identity)
        MarkParser.newDocument


manifest =
    { backgroundColor = Just Color.white
    , categories = [ Pages.Manifest.Category.education ]
    , displayMode = Manifest.MinimalUi
    , orientation = Manifest.Portrait
    , description = siteTagline
    , iarcRatingId = Nothing
    , name = "Incremental Elm Consulting"
    , themeColor = Just Color.white
    , startUrl = pages.index
    , shortName = Just "Incremental Elm"
    , sourceIcon = images.icon
    }


siteTagline =
    "Incremental Elm Consulting"


type alias Model =
    { menuBarAnimation : View.MenuBar.Model
    , menuAnimation : Animation.State
    , dimensions : Dimensions
    , styles : List Animation.State
    , showMenu : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { styles = ElmLogo.polygons |> List.map Animation.style
      , menuBarAnimation = View.MenuBar.init
      , menuAnimation =
            Animation.style
                [ Animation.opacity 0
                ]
      , dimensions =
            Dimensions.init
                { width = 0
                , height = 0
                , device = Element.classifyDevice { height = 0, width = 0 }
                }
      , showMenu = False
      }
        |> updateStyles
    , Dom.getViewport
        |> Task.perform InitialViewport
    )


updateStyles : Model -> Model
updateStyles model =
    { model
        | styles =
            model.styles
                |> List.indexedMap makeTranslated
    }


type Msg
    = StartAnimation
    | Animate Animation.Msg
    | InitialViewport Dom.Viewport
    | WindowResized Int Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitialViewport { viewport } ->
            ( { model
                | dimensions =
                    Dimensions.init
                        { width = viewport.width
                        , height = viewport.height
                        , device =
                            Element.classifyDevice
                                { height = round viewport.height
                                , width = round viewport.width
                                }
                        }
              }
            , Cmd.none
            )

        WindowResized width height ->
            ( { model
                | dimensions =
                    Dimensions.init
                        { width = toFloat width
                        , height = toFloat height
                        , device = Element.classifyDevice { height = height, width = width }
                        }
              }
            , Cmd.none
            )

        StartAnimation ->
            case model.showMenu of
                True ->
                    ( { model
                        | showMenu = False
                        , menuBarAnimation = View.MenuBar.startAnimation model
                        , menuAnimation =
                            model.menuAnimation
                                |> Animation.interrupt
                                    [ Animation.toWith interpolation
                                        [ Animation.opacity 100
                                        ]
                                    ]
                      }
                    , Cmd.none
                    )

                False ->
                    ( { model
                        | showMenu = True
                        , menuBarAnimation = View.MenuBar.startAnimation model
                        , menuAnimation =
                            model.menuAnimation
                                |> Animation.interrupt
                                    [ Animation.toWith interpolation
                                        [ Animation.opacity 100
                                        ]
                                    ]
                      }
                    , Cmd.none
                    )

        Animate time ->
            ( { model
                | styles = List.map (Animation.update time) model.styles
                , menuBarAnimation = View.MenuBar.update time model.menuBarAnimation
                , menuAnimation = Animation.update time model.menuAnimation
              }
            , Cmd.none
            )


interpolation =
    Animation.easing
        { duration = second * 1
        , ease = Ease.inOutCubic
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Animation.subscription Animate
            (model.styles
                ++ View.MenuBar.animationStates model.menuBarAnimation
                ++ [ model.menuAnimation ]
            )
        , Browser.Events.onResize WindowResized
        ]


header : Model -> Element Msg
header model =
    View.Navbar.view model animationView StartAnimation


animationView model =
    svg
        [ version "1.1"
        , x "0"
        , y "0"
        , viewBox "0 0 323.141 322.95"
        , width "100%"
        ]
        [ Svg.g []
            (List.map (\poly -> polygon (Animation.render poly) []) model.styles)
        ]
        |> Element.html
        |> Element.el
            [ Element.padding 20
            , Element.height Element.shrink
            , Element.alignTop
            , Element.alignLeft
            , Element.width (Element.px 100)
            ]


translate n =
    Animation.translate (Animation.px n) (Animation.px n)


second =
    1000


makeTranslated i polygon =
    polygon
        |> Animation.interrupt
            [ Animation.set
                [ translate -1000
                , Animation.scale 1
                ]
            , Animation.wait
                (second
                    * toFloat i
                    * 0.1
                    + (((toFloat i * toFloat i) * second * 0.05) / (toFloat i + 1))
                    |> round
                    |> Time.millisToPosix
                )
            , Animation.to
                [ translate 0
                , Animation.scale 1
                ]
            ]


view : Model -> List ( List String, Metadata Msg ) -> Page (Metadata Msg) (List (Element Msg)) -> { title : String, body : Html Msg }
view model allMetadata pageOrPost =
    let
        { title, body } =
            pageOrPostView model pageOrPost
    in
    { title = title
    , body =
        (if model.showMenu then
            Element.column
                [ Element.height Element.fill
                , Element.alignTop
                , Element.width Element.fill
                ]
                [ View.Navbar.view model animationView StartAnimation
                , View.Navbar.modalMenuView model.menuAnimation
                ]

         else
            body
        )
            |> Element.layout
                [ Element.width Element.fill
                ]
    }


pageOrPostView : Model -> Page (Metadata Msg) (List (Element Msg)) -> { title : String, body : Element Msg }
pageOrPostView model pageOrPost =
    case pageOrPost.metadata of
        Metadata.Page metadata ->
            { title = metadata.title
            , body =
                [ header model
                , pageOrPost.view
                    |> Element.textColumn
                        [ Element.centerX
                        , Element.width Element.fill
                        , Element.spacing 30
                        , Font.size 18
                        ]
                    |> Element.el
                        [ if Dimensions.isMobile model.dimensions then
                            Element.width (Element.fill |> Element.maximum 600)

                          else
                            Element.width Element.fill
                        , Element.height Element.fill
                        , if Dimensions.isMobile model.dimensions then
                            Element.padding 20

                          else
                            Element.paddingXY 200 50
                        , Element.spacing 30
                        ]
                ]
                    |> Element.column [ Element.width Element.fill ]
            }

        Metadata.Article metadata ->
            { title = metadata.title.raw
            , body =
                [ header model
                , ((metadata.title.styled
                        |> Element.paragraph [ Font.size 36, Font.center, Font.family [ Font.typeface "Raleway" ], Font.bold ]
                   )
                    :: (Element.image
                            [ Element.width (Element.fill |> Element.maximum 600)
                            , Element.centerX
                            ]
                            { src = metadata.coverImage
                            , description = metadata.title.raw
                            }
                            |> Element.el [ Element.centerX ]
                       )
                    :: pageOrPost.view
                  )
                    |> Element.textColumn
                        [ Element.centerX
                        , Element.width Element.fill
                        , Element.spacing 30
                        , Font.size 18
                        ]
                    |> Element.el
                        [ if Dimensions.isMobile model.dimensions then
                            Element.width (Element.fill |> Element.maximum 600)

                          else
                            Element.width (Element.fill |> Element.maximum 700)
                        , Element.height Element.fill
                        , Element.padding 30
                        , Element.spacing 20
                        , Element.centerX
                        ]
                ]
                    |> Element.column [ Element.width Element.fill ]
            }

        Metadata.Learn metadata ->
            { title = metadata.title
            , body =
                [ header model
                , pageOrPost.view
                    |> Element.textColumn
                        [ Element.centerX
                        , Element.width Element.fill
                        , Element.spacing 30
                        , Font.size 18
                        ]
                    |> Element.el
                        [ if Dimensions.isMobile model.dimensions then
                            Element.width (Element.fill |> Element.maximum 600)

                          else
                            Element.width (Element.fill |> Element.maximum 700)
                        , Element.height Element.fill
                        , Element.padding 20
                        , Element.spacing 20
                        , Element.centerX
                        ]
                ]
                    |> Element.column [ Element.width Element.fill ]
            }


{-| <https://developer.twitter.com/en/docs/tweets/optimize-with-cards/overview/abouts-cards>
<https://htmlhead.dev>
<https://html.spec.whatwg.org/multipage/semantics.html#standard-metadata-names>
<https://ogp.me/>
-}
head : Metadata.Metadata msg -> List (Head.Tag PagesNew.PathKey)
head metadata =
    case metadata of
        Metadata.Page meta ->
            Head.Seo.summaryLarge
                { canonicalUrlOverride = Nothing
                , siteName = siteName
                , image =
                    { url = PagesNew.images.icon
                    , alt = meta.title
                    , dimensions = Nothing
                    , mimeType = Nothing
                    }
                , description = meta.title
                , title = meta.title
                , locale = Nothing
                }
                |> Head.Seo.website

        Metadata.Article meta ->
            let
                twitterUsername =
                    "dillontkearns"

                twitterSiteAccount =
                    "incrementalelm"

                image =
                    fullyQualifiedUrl meta.coverImage
            in
            Head.Seo.summaryLarge
                { canonicalUrlOverride = Nothing
                , siteName = siteName
                , image =
                    -- TODO fix image
                    { url = PagesNew.images.architecture
                    , alt = meta.description.raw
                    , dimensions = Nothing
                    , mimeType = Nothing
                    }
                , description = meta.description.raw
                , title = meta.title.raw
                , locale = Nothing
                }
                |> Head.Seo.article
                    { tags = []
                    , section = Nothing
                    , publishedTime = Nothing
                    , modifiedTime = Nothing
                    , expirationTime = Nothing
                    }

        Metadata.Learn meta ->
            []


ensureAtPrefix : String -> String
ensureAtPrefix twitterUsername =
    if twitterUsername |> String.startsWith "@" then
        twitterUsername

    else
        "@" ++ twitterUsername


fullyQualifiedUrl : String -> String
fullyQualifiedUrl url =
    let
        urlWithoutLeadingSlash =
            if url |> String.startsWith "/" then
                url |> String.dropLeft 1

            else
                url
    in
    "https://incrementalelm.com" ++ url


siteName =
    "Incremental Elm Consulting"
