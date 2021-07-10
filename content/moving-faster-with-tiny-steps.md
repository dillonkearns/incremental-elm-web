---
description: In this post, we're going to be looking up an Article in an Elm Dict, using the tiniest steps possible.
publishAt: "2020-01-01"
cover: 1523005023961-0f525418b9cb
---

# Moving Faster with Tiny Steps in Elm

Why use tiny steps? Simple! Because we want to write Elm code faster, and with more precise error messages to guide us through each step.

## Setting Up Your Environment

The point of taking tiny steps is that you get constant, clear feedback. So before I walk through the steps, here are some things to set up in your editor to help you get more feedback:

- See Elm compiler errors instantly without manually running a command. For example, have elm-make run whenever your files change. Or run elm-live, webpack, or parcel in watch mode.
- Even better, get error messages in your editor whenever you save. Here are some instructions for configuring Atom with in-editor compiler errors.
- Note that with both of these workflows, I recommend saving constantly so you get instant error messages.
- Atom also gives you auto-completion, which is another helpful form of feedback. `intellij-elm` is another good option for this.

## The Problem

We're doing a simple blog page that looks up articles based on the URL. We've already got the wiring to get the article name from the URL (for example, localhost:8000/article/`articlePath`). Now we just need to take that `articlePath` and use it to look up the title and body of our article in a Dict.

## The Tiny Steps

If you'd like to see a short video of each of these steps, or download the code so you can try them for yourself, just sign up here and I'll send you a link.

Okay, now let's walk through our tiny steps for building our Dict!

## Step 0

Always respond with "Article Not Found."

We start with the failure case because it's easiest. This is sort of like returning 1 for for factorial(1). It's just an easy way to get something working and compiling. Think of this as our "base case".

```elm
view : Maybe String -> Browser.Document msg
view maybeArticlePath =
    articleNotFoundDocument

articleNotFoundDocument : Browser.Document msg
articleNotFoundDocument =
    { title = "Article Not Found"
    , body = [ text "Article not found..." ]
    }
```

We've wired up our code so that when the user visits mysite.com/article/hello, you'll see our "Article Not Found" page.

## Step 1

Hard code an empty dictionary.

```elm
view : Maybe String -> Browser.Document msg
view maybeArticlePath =
    Dict.get articlePath Dict.empty
        |> Maybe.map articleDocument
        |> Maybe.withDefault articleNotFoundDocument
```

Why bother? We know this lookup will always give back Nothing! So we haven't changed the behavior at all.

This step is actually quite powerful. We've wired up our entire pipeline to reliably do a dictionary lookup and get back Nothing every time! Why is this so useful? Well, look at what we accomplish with this easy step:

- We've made the necessary imports
- We know that all the puzzle pieces fit perfectly together!
- So even though we've done almost nothing, the work that remains is all teed up for us! This is the power of incremental steps. We've stripped out all the risk because we know that the whole picture ties together correctly.

When you mix in the hard part (building the actual business logic) with the "easy part" (the wiring), you end up with something super hard! But when you do the wiring first, you can completely focus on the hard part once that's done. And amazingly, this small change in our approach makes it a lot easier.

## Step 2

Extract the dictionary to a top-level value.

```elm
view : Maybe String -> Browser.Document msg
view maybeArticlePath =
    Dict.get articlePath articles
        |> Maybe.map articleDocument
        |> Maybe.withDefault articleNotFoundDocument

articles =
    Dict.empty
```

This is just a simple refactor. We can refactor at any step. This is more than a superficial change, though. Pulling out this top-level value allows us to continue tweaking this small area inside a sort of sandbox. This will be much easier with a type-annotation, though…

## Step 3

Annotate our articles top-level value.

```elm
view : Maybe String -> Browser.Document msg
view maybeArticlePath =
    Dict.get articlePath articles
        |> Maybe.map articleDocument
        |> Maybe.withDefault articleNotFoundDocument

articles : Dict String Article
articles =
    Dict.empty
```

This step is important because it allows the Elm compiler to give us more precise and helpful error messages. It can now pinpoint exactly where things go wrong if we take a misstep. Importantly, we're locking in the type annotation at a time when everything compiles already so we know things line up. If we added the type annotation when things weren't fully compiling, we wouldn't be very confident that we got it right.

## Step 4

Use a "synonym" for Dict.empty.

```elm
articles : Dict String Article
articles =
    Dict.fromList []
```

What's a synonym? Well, it's just a different way to say the exact same thing.

Kent Beck calls this process "Make the change easy, then make the easy change." Again, this is all about teeing ourselves up to make the next step trivial.

## Step 5

Add a single item to your dictionary

```elm
Dict.fromList
    [ ( "hello"
        , { title = "Hello!",
            body = "Here's a nice article for you! 🎉"
          }
        )
    ]
```

Now that we've done all those other steps, this was super easy! We know exactly what this data structure needs to look like in order to get the type of data we need, because we've already wired it up! And when we finally wire it up, everything just flows through uneventfully. Perhaps it's a bit anti-climactic, but hey, it's effective!

But isn't this just a toy example to illustrate a technique. While this technique is very powerful when it comes to more sophisticated problems, trust me when I say this is how I write code all the time, even when it's as trivial as creating a dictionary. And I promise you, having this technique in your tool belt will make it easier to write Elm code!

## Step 6

In this example, we were dealing with hardcoded data. But it's easy to imagine grabbing this list from a database or an API. I'll leave this as an exercise for the reader, but let's explore the benefits.

When you start with small steps, removing hard-coding step by step, it lets you think up front about the ideal data structure. This ideal data structure dictates your code, and then from there you figure out how to massage the data from your API into the right data structure. It's easy to do things the other way around and let our JSON structures dictate how we're storing the data on the client.

## Thanks for Reading!

You can sign up here for more tips on writing Elm code incrementally. When you sign up, I'll send the 3-minute walk-through video of each of these steps, and the download link for the starting-point code and the solution.

Let me know how this technique goes! I've gotten a lot of great feedback from my clients about this approach, and I love hearing success stories. I'd love to hear how you're able to apply this in your day-to-day work!
