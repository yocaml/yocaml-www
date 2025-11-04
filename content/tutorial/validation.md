---
title: Data validation and Metadata
description: Understanding how to create and validate data
synopsis: 
  Dans le cours sur la création d'un blog, nous avions utilisé 
  des _Archétypes_ préfabriqués comme `Page`, `Article` et `Articles`.
  Dans ce guide, nous allons comprendre comment utiliser le langage
  de description de données embarqué dans YOCaml pour créer des données
  que l'on peut valider, depuis un format de données variable et que
  l'on pourra injecter (ou sérialiser) dans des moteurs de templates
  comme _Mustach_ ou _Jingoo_.
date: 2025-09-27
updates:
  - key: 2025-09-27
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>", "xvw <xaviervdw@gmail.com>"]
---

En effet, pour **être le plus générique possible**, YOCaml fournit une
bibliothèque pour permettre de **décrire** de la données arbitraires
(que l'on pourra transformer dans le langage de description d'un
moteur de template, _arbitrairement_ ou sérialiser dans la forme de
notre choix) et pour être **validée**, depuis un format arbitraire.

## Validation et projection

Quand on construit un générateur de sites, _statiquement ou non_, on
veut généralement pouvoir attacher des _métadonnées_ à des documents
pour contrôler la manière dont ou voudra les rendre (en HTML par
exemple). Pour ça, nous devons être capable de trois choses
essentielles :

- **Extraire les métadonnées du document**: soit _décrire_ de quelle
  manière les données sont incluses dans un document. Dans les
  exemples précédent, nous avions utilisés [l'approche du Front
  Matter](https://jekyllrb.com/docs/front-matter/), consistant
  simplement à utiliser `---` pour séparer les métadonnées du
  document.
  
- **Valider les métadonnées extraites**: soit s'assurer que le
  document contient bien les données nécéssaires (et qu'elles ont la
  bonne forme). Dans YOCaml, on utilise un format spécifique,
  [`Yocaml.Data.t`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#type-t). En
  effet, on extrait les métadonnées selon une stratégie d'extraction,
  ensuite depuis un format source (par exemple `Yaml`, `ToML` ou
  encore `Sexp`), on le convertit dans le format `Yocaml.Data.t`,
  ensuite on applique des validations nous permettant de convertir
  notre `Yocaml.Data.t` vers un type de notre choix.
  
  
- **Injecter les données validées**: une fois que nos donnéees sont
  validées, on voudrait pouvoir générer _concrètement_ notre document,
  donc transformer notre type en `Yocaml.Data.t` (et laisser YOCaml
  convertir vers le langage compris par le moteur de templates).

Vous l'aurez compris, pour assurer d'être le plus générique possible,
de pouvoir s'adapter au plus de situations possibles, YOCaml passe par
un format de représentation intermédiaire très simple, qui fera office
de relais.

Voici un exemple schématique de la manière dont le processus de
génération d'hypothétiques articles fonctionne, de la lecture à
l'écriture:

![From metadata to artifact](/assets/images/data-flow.svg)

La généricité du traitement des métadonnées est articulée autours de
plusieurs signatures :

- [Yocaml.Required.DATA_PROVIDER](https://yocaml.github./doc/yocaml/yocaml/Yocaml/Required/module-type-DATA_PROVIDER/index.html)
  test
