# =============================================================================
# transforEmotion ja suomi: pieni kielikoe
# -----------------------------------------------------------------------------
# Aineisto: XED (Öhman ym. 2020, Helsinki-NLP/XED, CC-BY 4.0), elokuvatekstitykset,
#   Plutchikin 8 perustunnetta. Otos: vain yhden tunteen lauseet, >= 4 sanaa,
#   25 lausetta / tunne / kieli (fi 200, en 200), seed 2026 -> xed_otos.csv
#
# Asetelmat (kaikki zero-shot, yksi luokka per lause = argmax):
#   A  EN-teksti, oletusmalli (DistilRoBERTa), EN-luokat         -> englannin vertailutaso
#   B  FI-teksti, oletusmalli, EN-luokat                         -> "naiivi" käyttö suomella
#   C  FI-teksti, mDeBERTa-xnli, EN-luokat                       -> monikielinen malli
#   D  FI-teksti, mDeBERTa-xnli, FI-luokat (EN-pohja "This example is {}.")
#                                                                -> mitä transforEmotion tekee, jos luokat annetaan suomeksi
#   E  FI-teksti, mDeBERTa-xnli, FI-luokat partitiivissa + FI-pohja
#      "Tämä teksti ilmaisee {}."  (ohittaa transforEmotionin, sama HF-putki)
#   (F valinnainen) FI -> EN konekäännös (Helsinki-NLP/opus-mt-fi-en) + oletusmalli
#
# Edellyttää: transforEmotion asennettu + te-koe-virtuaaliympäristö (ks. alla).
# Ajoaika CPU:lla arviolta 10-20 min.
# =============================================================================

# AJA TÄMÄ TUOREESSA R-ISTUNNOSSA (RStudio: Session > Restart R) JA YLHÄÄLTÄ ALAS.
#
# Python-ympäristö luodaan ETUKÄTEEN PowerShellissä uv:llä (kerran).
# Pohjana koneelle jo asennettu python.org-Python 3.14, koska Windowsin
# sovellusten hallintakäytäntö estää uv:n itse lataaman Pythonin DLL:t.
#
#   uv venv "$env:USERPROFILE\te-koe314" --python "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe"
#   uv pip install --python "$env:USERPROFILE\te-koe314\Scripts\python.exe" torch transformers sentencepiece protobuf sacremoses
#   & "$env:USERPROFILE\te-koe314\Scripts\python.exe" -c "import socket, torch, transformers; print(torch.__version__, transformers.__version__)"
#
# Nimetty virtuaaliympäristö + use_virtualenv(required = TRUE) ohittaa muut
# Python-valinnat (esim. RStudion Global Options > Python).

venv <- file.path(Sys.getenv("USERPROFILE"), "te-koe314")
if (!dir.exists(venv)) stop("Ympäristöä ei löydy: ", venv,
                            "\nLuo se PowerShellissä (ks. ohje yllä).")
if (isTRUE(reticulate::py_available(initialize = FALSE))) {
  stop("Python on jo käynnissä tässä istunnossa. Käynnistä R uudelleen ",
       "(Session > Restart R) ja aja skripti alusta.")
}
reticulate::use_virtualenv(venv, required = TRUE)
hf <- reticulate::import("transformers")
message("Python: ", reticulate::py_config()$python,
        " | transformers ", hf$`__version__`)

library(transforEmotion)

# Aseta työkansioksi kansio, jossa xed_otos.csv on
setwd("C:/Users/maria/OneDrive - University of Helsinki/Dariah2026_/testausta")
otos <- read.csv("xed_otos.csv", fileEncoding = "UTF-8", stringsAsFactors = FALSE)
fi <- otos[otos$lang == "fi", ]
en <- otos[otos$lang == "en", ]

emo_en  <- c("anger", "anticipation", "disgust", "fear",
             "joy", "sadness", "surprise", "trust")
emo_fi  <- c("viha", "odotus", "inho", "pelko",
             "ilo", "suru", "yllätys", "luottamus")
emo_fip <- c("vihaa", "odotusta", "inhoa", "pelkoa",          # partitiivi
             "iloa", "surua", "yllätystä", "luottamusta")      # "Tämä teksti ilmaisee ___"
names(emo_fi) <- names(emo_fip) <- emo_en

MDEBERTA <- "MoritzLaurer/mDeBERTa-v3-base-mnli-xnli"

# --- apufunktiot --------------------------------------------------------------

# transformer_scores() palauttaa listan nimettyjä pistevektoreita -> argmax
ennusta_te <- function(teksti, luokat, malli) {
  s <- transformer_scores(text = teksti, classes = luokat, transformer = malli)
  vapply(s, function(v) names(v)[which.max(v)], character(1), USE.NAMES = FALSE)
}

# Sama HF-putki suoraan, jotta hypothesis_template voidaan vaihtaa
ennusta_hf <- function(teksti, luokat, malli, pohja) {
  clf <- hf$pipeline("zero-shot-classification", model = malli)
  vapply(teksti, function(x) {
    r <- clf(x, luokat, hypothesis_template = pohja, multi_label = FALSE)
    r$labels[[1]]
  }, character(1), USE.NAMES = FALSE)
}

takaisin_en <- function(pred, sanasto) names(sanasto)[match(pred, sanasto)]

arvioi <- function(gold, pred) {
  acc <- mean(gold == pred)
  f1 <- sapply(emo_en, function(k) {
    tp <- sum(pred == k & gold == k); fp <- sum(pred == k & gold != k)
    fn <- sum(pred != k & gold == k)
    if (tp == 0) return(0)
    p <- tp / (tp + fp); r <- tp / (tp + fn); 2 * p * r / (p + r)
  })
  c(accuracy = acc, macro_F1 = mean(f1))
}

# --- ajot ------------------------------------------------------------------
tulos <- list()
t0 <- Sys.time()

tulos$A <- ennusta_te(en$text, emo_en, "cross-encoder-distilroberta")
tulos$B <- ennusta_te(fi$text, emo_en, "cross-encoder-distilroberta")
tulos$C <- ennusta_te(fi$text, emo_en, MDEBERTA)
tulos$D <- takaisin_en(ennusta_te(fi$text, unname(emo_fi), MDEBERTA), emo_fi)
tulos$E <- takaisin_en(ennusta_hf(fi$text, unname(emo_fip), MDEBERTA,
                                  "Tämä teksti ilmaisee {}."), emo_fip)

# F: konekäännös (ohitetaan, jos käännösmalli ei lataudu)
tulos$F <- tryCatch({
  kaantaja <- hf$pipeline("translation", model = "Helsinki-NLP/opus-mt-fi-en")
  fi_en <- vapply(fi$text, function(x) kaantaja(x)[[1]]$translation_text,
                  character(1), USE.NAMES = FALSE)
  fi$text_en_mt <- fi_en
  ennusta_te(fi_en, emo_en, "cross-encoder-distilroberta")
}, error = function(e) { message("F ohitettu: ", conditionMessage(e)); NULL })

message("Ajoaika: ", format(Sys.time() - t0))

# --- yhteenveto ---------------------------------------------------------------
kuvaus <- c(
  A = "EN-teksti | oletusmalli | EN-luokat (vertailutaso)",
  B = "FI-teksti | oletusmalli | EN-luokat",
  C = "FI-teksti | mDeBERTa | EN-luokat",
  D = "FI-teksti | mDeBERTa | FI-luokat + EN-pohja",
  E = "FI-teksti | mDeBERTa | FI-luokat + FI-pohja",
  F = "FI->EN konekäännös | oletusmalli | EN-luokat"
)
yht <- do.call(rbind, lapply(names(tulos), function(k) {
  if (is.null(tulos[[k]])) return(NULL)
  gold <- if (k == "A") en$gold else fi$gold
  m <- arvioi(gold, tulos[[k]])
  data.frame(asetelma = k, kuvaus = kuvaus[[k]],
             accuracy = round(m[["accuracy"]], 3),
             macro_F1 = round(m[["macro_F1"]], 3))
}))
cat("\nSattuman taso 8 tasakokoisella luokalla: 0.125\n\n")
print(yht, row.names = FALSE)

# Mitä luokkaa kukin asetelma suosii? (vinouma yhteen luokkaan on yleistä zero-shotissa)
cat("\nEnnusteiden jakauma:\n")
print(sapply(tulos[!sapply(tulos, is.null)],
             function(p) table(factor(p, levels = emo_en))))

# --- tallennus ----------------------------------------------------------------
ennusteet_fi <- data.frame(fi[, c("id", "text", "gold")],
                           tulos[c("B", "C", "D", "E", "F")[!sapply(tulos[c("B","C","D","E","F")], is.null)]])
ennusteet_en <- data.frame(en[, c("id", "text", "gold")], A = tulos$A)
write.csv(yht, "kielikoe_yhteenveto.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(ennusteet_fi, "kielikoe_ennusteet_fi.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(ennusteet_en, "kielikoe_ennusteet_en.csv", row.names = FALSE, fileEncoding = "UTF-8")
