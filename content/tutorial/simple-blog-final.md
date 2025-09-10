---
title: Final words
description: Conclusion on the entire tutorial
synopsis: 
  We now have **a fully functional blog**, and it’s 
  time to wrap things up.
date: 2025-09-10
updates:
  - key: 2025-09-10
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>"]
---

We’ve had the chance to explore a _large collection of YOCaml
features_, but there’s still **so much more**! In this final section,
we’ll suggest a few ideas for improvements to encourage you to use
YOCaml **for all your statically generated sites**!

## Going Further

As mentioned in [the subjective
highlights](/tutorial/why.html#against-the-boring-normalized-web), the
goal of YOCaml is to provide efficient and composable tools for
building a website generator perfectly tailored to the user’s
needs. That’s why the standard YOCaml distribution does not include
any _bundles_ for quickly creating a site. The first simple step you
could take is to customize the templates we used or, **even better**,
rewrite your entire site from scratch, giving free rein to your
imagination and ambitions!


### Publishing Your Site

In this guide, we haven’t covered deployment at all. This is mainly
because, _often_ (except when generating a site in a [Git
repository](https://ocaml.org/p/yocaml_git/latest)), the artifacts are
generated in a directory (in our tutorial, `_www`), making deployment
_trivial_. You simply need to move the contents of the directory to
your server.

> If you want to use [GitHub Pages](https://docs.github.com/en/pages)
> to deploy your site, the
> [actions-gh-pages](https://github.com/peaceiris/actions-gh-pages)
> action is well documented. You can find an example of deployment
> [here](https://github.com/yocaml/yocaml-www/blob/main/.github/workflows/deploy.yml),
> which was used to deploy this manual.


### Code Organization

For simplicity, we implemented our generator entirely in the `blog.ml`
file. An obvious improvement would be to reorganize your binary into
multiple modules.

### Documentation

The [YOCaml documentation](https://yocaml.github.io/doc/) is quite
extensive, but since you’ve followed this tutorial, you should now be
more familiar with the concepts involved, making it easier to
navigate. We encourage you to explore it for alternative explanations
of what we’ve covered and to find new ideas for possible
implementations!

#### Specific Tutorials

In addition to the documentation, you’ll find specific tutorials in
the _sidebar_ that cover particular aspects of YOCaml. We encourage
you to explore them to become increasingly proficient!


## Improvements

Even though a project **can always be improved**, some aspects were
intentionally left aside to keep this tutorial simple. For example,
while we praised **YOCaml’s minimalism**, we realize that articles are
still traversed and parsed three times:

- To build each page dedicated to an article
- To create the index
- To generate the ATOM feed

In practice, **this is far from a problem**, because, let’s be honest,
reaching a writing frequency high enough for parsing articles three
times to become an issue is quite ambitious.

However, during our iterations and _batches_, we mainly used the
`Batch.iter_files` action. If you check the
[`Batch`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Batch/index.html)
module, you’ll quickly see there are many alternatives. For example,
when traversing the articles, you could use
[`fold_files`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Batch/index.html#val-fold_files)
to **maintain the list of articles just once**, and then use it to
build both the index and the feed.


## Conclusion

The tutorial is coming to an end! We hope it has motivated you to
seriously use YOCaml to build your own website, because **we believe
this is very important for a diverse web**. Additionally, from our
perspective, maintaining your own website is an **interesting and
useful** exercise.

YOCaml’s API is extensive yet designed to be modular, allowing you to
build a site generator _generically_ that perfectly fits your
needs. While this requires a small investment in writing code, it
ultimately simplifies your workflow.

Please don’t hesitate to [give us
feedback](https://github.com/yocaml/yocaml-www/issues) on how to
improve this tutorial, the YOCaml API, or to request additional
tutorials. We are very receptive to suggestions and always happy to
receive _feedback_.
