module Style exposing (..)

import Animation
import Element
import Element.Font


fonts =
    { title = Element.Font.family [ Element.Font.typeface "Open Sans" ]
    , body = Element.Font.family [ Element.Font.typeface "Raleway" ]
    }


fontSize =
    { body = Element.Font.size 25
    , title = Element.Font.size 55
    , medium = Element.Font.size 36
    , small = Element.Font.size 18
    , logo = Element.Font.size 50
    }


mobileFontSize =
    { body = Element.Font.size 65
    , title = Element.Font.size 95
    , medium = Element.Font.size 76
    , small = Element.Font.size 58
    , logo = Element.Font.size 90
    }


palette =
    { main = elementRgb 216 219 226
    , bold = elementRgb 0 23 31
    , light = elementRgb 0 126 167
    , highlight = elementRgb 0 168 232
    , mainBackground = elementRgb 255 255 255
    , highlightBackground = elementRgb 0 52 89
    }


hoverPalette =
    { main = highlightRgb 216 219 226
    , bold = highlightRgb 0 23 31
    , light = highlightRgb 0 126 167
    , highlight = highlightRgb 0 168 232
    , mainBackground = highlightRgb 255 255 255
    , highlightBackground = highlightRgb 0 52 89
    }


highlightFactor =
    25


highlightRgb red green blue =
    elementRgb (red + highlightFactor) (green + highlightFactor) (blue + highlightFactor)


elementRgb red green blue =
    Element.rgb (red / 255) (green / 255) (blue / 255)


rgb : Int -> Int -> Int -> Animation.Color
rgb red green blue =
    { red = red
    , green = green
    , blue = blue
    , alpha = 1.0
    }


animationPalette =
    { main = rgb 216 219 226
    , bold = rgb 0 23 31
    , light = rgb 0 126 167
    , highlight = rgb 0 168 232
    , mainBackground = rgb 255 255 255
    , highlightBackground = rgb 0 52 89
    }
