---
layout: task
title: "Safety kit for social statistics users"
task_id: KIT
permalink: /kit/
summary: "Practical guidance and safeguards for people working with social statistics in an AI-assisted workflow."
---

An infrastructure-level deliverable: practical guidance and safeguards for people 
working with social statistics in an AI-assisted workflow. Forthcoming guidance 
will e.g. review optimal AI techniques and tools.

## Background

*(Add background text here — what problem this task addresses, and why
generative AI and LLMs are relevant to social science data analysis.)*

## Approach

*(Add a short description of the methods or tools being developed.)*

## Outputs

- Check the language before you trust the scores ([PDF]({{ '/assets/kit/surveyai-kit-language-check.pdf' | relative_url }}), October 2026). Many sentiment and emotion tools are built on English language models but accept text in any language. We tested the R package transforEmotion on Finnish movie subtitles. With its default settings, its results were no better than chance, and it gave no warning. With a multilingual model, Finnish results came close to the English baseline. The note includes a short checklist for anyone applying NLP tools to non-English text, along with the R script and data sample for reproducing the test.
- [Using RAG](https://dariah-fi-surveyai.github.io/SurveyDokum/articles/using-rag.html)

## Tools
- [transforEmotion: Sentiment Analysis for Text, Image and Video Using Transformer Models](https://github.com/atomashevic/transforEmotion)

