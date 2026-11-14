# =============================================================================
#  TABLEAU DE BORD - FILIERE CAFE-CACAO EN COTE D'IVOIRE
#  Livrable 3 : Dashboard R Shiny (app.R)
#  Projet AS2 - Conception de tableaux de bord - 2025/2026
#
#  Lancement :  ouvrir ce fichier dans RStudio puis cliquer "Run App"
#               ou en console :  shiny::runApp()
# =============================================================================

# ---- 1. Packages ------------------------------------------------------------
# Installez-les une seule fois si besoin (decommentez la ligne ci-dessous) :
# install.packages(c("shiny","shinydashboard","readxl","dplyr","tidyr",
#                     "plotly","DT","scales"))

library(shiny)
library(shinydashboard)
library(readxl)
library(dplyr)
library(tidyr)
library(plotly)
library(DT)
library(scales)

# ---- 2. Chargement et preparation des donnees -------------------------------
# Les vrais en-tetes de colonnes se trouvent en ligne 3 de chaque feuille
# (lignes 1-2 = titres), d'ou skip = 2.

fichier <- "Base_Donnees_AS2_2026_Cafe_Cacao_CI.xlsx"

if (!file.exists(fichier)) {
  stop(paste0("Fichier introuvable : ", fichier,
              "\nPlacez app.R dans le meme dossier que le classeur Excel."))
}

coop <- read_excel(fichier, sheet = "BASE1_Cooperatives",         skip = 2)
expo <- read_excel(fichier, sheet = "BASE2_Exportations_Marche",  skip = 2)
impa <- read_excel(fichier, sheet = "BASE3_Impact_SocioEconomique", skip = 2)

# Nettoyage des types
coop <- coop %>%
  mutate(
    Annee_Creation = as.integer(format(as.Date(Date_Creation), "%Y")),
    across(c(Superficie_ha, Nb_Producteurs, Nb_Emplois_Directs,
             Rendement_Moyen_T_ha, Production_Totale_T,
             Prix_Bord_Champ_FCFA, Investissement_Total_FCFA,
             Taxes_Versees_FCFA, Deforestation_ha), as.numeric)
    # NB : Incidents_Travail_Enfant est categoriel (Aucun/Leger/Modere/Grave)
    #      -> laisse en texte, pas de conversion numerique.
  )

expo <- expo %>%
  mutate(across(c(Annee, Quantite_Exportee_T, Prix_Unitaire_USD,
                  Valeur_Totale_USD, Valeur_Totale_FCFA,
                  Frais_Logistique_FCFA, Valeur_Nette_FCFA,
                  Part_PIB_Pct, Taxes_Export_FCFA), as.numeric))

# On rattache a chaque exportation la Region et le Type_Culture de sa cooperative
expo <- expo %>%
  left_join(coop %>% select(ID_Coop, Region, Type_Culture),
            by = "ID_Coop")

impa <- impa %>%
  mutate(across(c(Annee_Rapport, Population_Zone, Emplois_Directs,
                  Emplois_Indirects, Taux_Emploi_Local_Pct,
                  Revenu_Moyen_Mensuel_FCFA, Budget_RSE_FCFA,
                  Nb_Ecoles_Construites, Nb_Centres_Sante,
                  Taux_Scolarisation_Pct, Acces_Eau_Potable_Pct,
                  Indice_Satisfaction_Pct), as.numeric))

# Listes de choix pour les filtres (construites depuis les donnees)
choix_regions <- sort(unique(coop$Region))
choix_culture <- sort(unique(coop$Type_Culture))
choix_annees  <- sort(unique(expo$Annee))

# Palette / theme graphique commun
pal <- c("#2e7d32", "#f9a825", "#6d4c41", "#0277bd",
         "#c62828", "#00838f", "#8e24aa", "#558b2f")

theme_plotly <- function(p, titre = "") {
  p %>% layout(
    title  = list(text = titre, font = list(size = 15)),
    font   = list(family = "Segoe UI, Arial"),
    margin = list(t = 45, r = 10, b = 40, l = 60),
    paper_bgcolor = "white", plot_bgcolor = "white",
    hoverlabel = list(bgcolor = "white")
  )
}

# Formatage nombres (espace comme separateur de milliers)
fmt <- function(x, suffixe = "") {
  paste0(format(round(x), big.mark = " ", scientific = FALSE), suffixe)
}

# =============================================================================
#  INTERFACE UTILISATEUR (UI)
# =============================================================================
ui <- dashboardPage(
  skin = "green",

  dashboardHeader(title = "Filiere Cafe-Cacao CI", titleWidth = 260),

  dashboardSidebar(
    width = 260,
    div(class = "sidebar-logo",
        img(src = "ENSEA.png", alt = "ENSEA")),
    sidebarMenu(
      id = "onglets",
      menuItem("Vue d'ensemble", tabName = "vue",     icon = icon("gauge-high")),
      menuItem("Production",     tabName = "prod",     icon = icon("seedling")),
      menuItem("Exportations",   tabName = "export",   icon = icon("ship")),
      menuItem("Impact socio-eco", tabName = "impact", icon = icon("people-group")),
      menuItem("Donnees",        tabName = "data",     icon = icon("table"))
    ),
    hr(),
    # ---- Filtres reactifs ----
    selectInput("f_region", "Region :",
                choices = c("Toutes", choix_regions), selected = "Toutes"),
    selectInput("f_culture", "Type de culture :",
                choices = c("Toutes", choix_culture), selected = "Toutes"),
    sliderInput("f_annee", "Campagne (annee) :",
                min = min(choix_annees), max = max(choix_annees),
                value = c(min(choix_annees), max(choix_annees)),
                step = 1, sep = ""),
    div(style = "padding:8px 15px; font-size:11px; color:#b8c7ce;",
        "Filtres appliques a l'ensemble du tableau de bord.")
  ),

  dashboardBody(
    tags$head(tags$style(HTML("
      .small-box h3{font-size:26px;} .box-title{font-weight:600;}
      /* Logo ENSEA en haut de la barre laterale */
      .sidebar-logo{ text-align:center; padding:12px 10px 6px; }
      .sidebar-logo img{ width:82px; border-radius:8px; }
      /* Bandeau d'en-tete de la page d'accueil */
      .banniere{ display:flex; align-items:center; justify-content:space-between;
                 gap:16px; background:#ffffff; border:1px solid #e3e6e8;
                 border-radius:10px; padding:14px 22px; margin-bottom:18px;
                 box-shadow:0 1px 3px rgba(0,0,0,.06); }
      .banniere img.logo-ensea{ height:66px; }
      .banniere img.logo-das{ height:60px; }
      .banniere .titre-projet{ text-align:center; flex:1; }
      .banniere .titre-projet h3{ margin:0; color:#1a3e6f; font-weight:700; }
      .banniere .titre-projet span{ color:#6d4c41; font-size:13px; }
      /* Pied de page */
      .pied-page{ text-align:center; color:#8a8f94; font-size:12px;
                  margin-top:26px; padding:14px; border-top:1px solid #e3e6e8; }
      .pied-page img{ height:34px; vertical-align:middle; margin-left:8px;
                      opacity:.9; }
    "))),
    tabItems(

      # ---------- ONGLET VUE D'ENSEMBLE ----------
      tabItem(
        tabName = "vue",
        div(class = "banniere",
            img(class = "logo-ensea", src = "ENSEA.png", alt = "ENSEA"),
            div(class = "titre-projet",
                h3("Tableau de bord - Filiere Cafe-Cacao en Cote d'Ivoire"),
                span("Projet AS2 | ENSEA - Division DAS | Periode 2018-2024")),
            img(class = "logo-das", src = "DAS.jpeg", alt = "DAS")),
        h2("Vue d'ensemble de la filiere"),
        fluidRow(
          valueBoxOutput("kpi_prod",  width = 3),
          valueBoxOutput("kpi_expo",  width = 3),
          valueBoxOutput("kpi_prod2", width = 3),
          valueBoxOutput("kpi_taxes", width = 3)
        ),
        fluidRow(
          valueBoxOutput("kpi_emploi", width = 3),
          valueBoxOutput("kpi_coop",   width = 3),
          valueBoxOutput("kpi_revenu", width = 3),
          valueBoxOutput("kpi_rende",  width = 3)
        ),
        fluidRow(
          box(title = "Production totale par region (T)", status = "success",
              solidHeader = TRUE, width = 6, plotlyOutput("g_prod_region", height = 300)),
          box(title = "Valeur des exportations par campagne (USD)", status = "success",
              solidHeader = TRUE, width = 6, plotlyOutput("g_expo_annee", height = 300))
        ),
        div(class = "pied-page",
            "Projet AS2 - Conception de tableaux de bord - ENSEA 2025/2026",
            img(src = "DAS.jpeg", alt = "DAS"))
      ),

      # ---------- ONGLET PRODUCTION ----------
      tabItem(
        tabName = "prod",
        h2("Production & cooperatives"),
        fluidRow(
          box(title = "Production par region", status = "success",
              solidHeader = TRUE, width = 6, plotlyOutput("p_region", height = 320)),
          box(title = "Repartition de la production par culture", status = "success",
              solidHeader = TRUE, width = 6, plotlyOutput("p_culture", height = 320))
        ),
        fluidRow(
          box(title = "Rendement moyen (T/ha) par region", status = "success",
              solidHeader = TRUE, width = 6, plotlyOutput("p_rende", height = 320)),
          box(title = "Top 10 cooperatives par production", status = "success",
              solidHeader = TRUE, width = 6, plotlyOutput("p_top", height = 320))
        )
      ),

      # ---------- ONGLET EXPORTATIONS ----------
      tabItem(
        tabName = "export",
        h2("Exportations & marche international"),
        fluidRow(
          box(title = "Valeur exportee par pays de destination (USD)", status = "primary",
              solidHeader = TRUE, width = 6, plotlyOutput("e_pays", height = 320)),
          box(title = "Repartition par type de produit", status = "primary",
              solidHeader = TRUE, width = 6, plotlyOutput("e_produit", height = 320))
        ),
        fluidRow(
          box(title = "Saisonnalite : valeur exportee par trimestre", status = "primary",
              solidHeader = TRUE, width = 6, plotlyOutput("e_trim", height = 320)),
          box(title = "Prix unitaire moyen (USD/T) par campagne", status = "primary",
              solidHeader = TRUE, width = 6, plotlyOutput("e_prix", height = 320))
        )
      ),

      # ---------- ONGLET IMPACT ----------
      tabItem(
        tabName = "impact",
        h2("Impact socio-economique"),
        fluidRow(
          box(title = "Revenu mensuel moyen par region (FCFA)", status = "warning",
              solidHeader = TRUE, width = 6, plotlyOutput("i_revenu", height = 320)),
          box(title = "Emplois directs vs indirects par region", status = "warning",
              solidHeader = TRUE, width = 6, plotlyOutput("i_emploi", height = 320))
        ),
        fluidRow(
          box(title = "Taux de scolarisation moyen (%) par region", status = "warning",
              solidHeader = TRUE, width = 6, plotlyOutput("i_scola", height = 320)),
          box(title = "Budget RSE total par region (FCFA)", status = "warning",
              solidHeader = TRUE, width = 6, plotlyOutput("i_rse", height = 320))
        )
      ),

      # ---------- ONGLET DONNEES ----------
      tabItem(
        tabName = "data",
        h2("Exploration des donnees (cooperatives)"),
        box(width = 12, status = "success", solidHeader = TRUE,
            title = "Table filtrable des cooperatives",
            DTOutput("table_coop"))
      )
    )
  )
)

# =============================================================================
#  SERVEUR (logique reactive)
# =============================================================================
server <- function(input, output, session) {

  # ---- Jeux de donnees filtres (reactifs) ----
  coop_f <- reactive({
    d <- coop
    if (input$f_region  != "Toutes") d <- d %>% filter(Region == input$f_region)
    if (input$f_culture != "Toutes") d <- d %>% filter(Type_Culture == input$f_culture)
    d
  })

  expo_f <- reactive({
    d <- expo %>%
      filter(Annee >= input$f_annee[1], Annee <= input$f_annee[2])
    if (input$f_region  != "Toutes") d <- d %>% filter(Region == input$f_region)
    if (input$f_culture != "Toutes") d <- d %>% filter(Type_Culture == input$f_culture)
    d
  })

  impa_f <- reactive({
    d <- impa %>%
      filter(Annee_Rapport >= input$f_annee[1], Annee_Rapport <= input$f_annee[2])
    if (input$f_region != "Toutes") d <- d %>% filter(Region == input$f_region)
    d
  })

  # =========================================================================
  #  KPI (value boxes) - au moins 8 indicateurs
  # =========================================================================
  output$kpi_prod <- renderValueBox({
    valueBox(fmt(sum(coop_f()$Production_Totale_T, na.rm = TRUE), " T"),
             "Production totale", icon = icon("wheat-awn"), color = "green")
  })
  output$kpi_expo <- renderValueBox({
    valueBox(fmt(sum(expo_f()$Valeur_Totale_USD, na.rm = TRUE) / 1e6, " M$"),
             "Valeur exportee (USD)", icon = icon("dollar-sign"), color = "olive")
  })
  output$kpi_prod2 <- renderValueBox({
    valueBox(fmt(sum(coop_f()$Nb_Producteurs, na.rm = TRUE)),
             "Producteurs", icon = icon("users"), color = "teal")
  })
  output$kpi_taxes <- renderValueBox({
    tot <- sum(coop_f()$Taxes_Versees_FCFA, na.rm = TRUE) +
           sum(expo_f()$Taxes_Export_FCFA, na.rm = TRUE)
    valueBox(fmt(tot / 1e9, " Md FCFA"),
             "Contribution fiscale", icon = icon("landmark"), color = "green")
  })
  output$kpi_emploi <- renderValueBox({
    valueBox(fmt(sum(coop_f()$Nb_Emplois_Directs, na.rm = TRUE)),
             "Emplois directs", icon = icon("briefcase"), color = "olive")
  })
  output$kpi_coop <- renderValueBox({
    valueBox(nrow(coop_f()),
             "Cooperatives", icon = icon("building"), color = "teal")
  })
  output$kpi_revenu <- renderValueBox({
    valueBox(fmt(mean(impa_f()$Revenu_Moyen_Mensuel_FCFA, na.rm = TRUE), " FCFA"),
             "Revenu mensuel moyen", icon = icon("money-bill-wave"), color = "green")
  })
  output$kpi_rende <- renderValueBox({
    valueBox(paste0(round(mean(coop_f()$Rendement_Moyen_T_ha, na.rm = TRUE), 2), " T/ha"),
             "Rendement moyen", icon = icon("chart-line"), color = "olive")
  })

  # =========================================================================
  #  ONGLET VUE D'ENSEMBLE
  # =========================================================================
  output$g_prod_region <- renderPlotly({
    d <- coop_f() %>% group_by(Region) %>%
      summarise(P = sum(Production_Totale_T, na.rm = TRUE)) %>%
      arrange(desc(P))
    plot_ly(d, x = ~reorder(Region, P), y = ~P, type = "bar",
            marker = list(color = pal[1])) %>%
      theme_plotly() %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "Tonnes"))
  })

  output$g_expo_annee <- renderPlotly({
    d <- expo_f() %>% group_by(Annee) %>%
      summarise(V = sum(Valeur_Totale_USD, na.rm = TRUE))
    plot_ly(d, x = ~Annee, y = ~V, type = "scatter", mode = "lines+markers",
            line = list(color = pal[4], width = 3),
            marker = list(color = pal[4], size = 8)) %>%
      theme_plotly() %>%
      layout(xaxis = list(title = "Campagne", dtick = 1),
             yaxis = list(title = "USD"))
  })

  # =========================================================================
  #  ONGLET PRODUCTION
  # =========================================================================
  output$p_region <- renderPlotly({
    d <- coop_f() %>% group_by(Region) %>%
      summarise(P = sum(Production_Totale_T, na.rm = TRUE)) %>% arrange(desc(P))
    plot_ly(d, x = ~reorder(Region, P), y = ~P, type = "bar",
            marker = list(color = pal[1])) %>%
      theme_plotly() %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "Tonnes"))
  })

  output$p_culture <- renderPlotly({
    d <- coop_f() %>% group_by(Type_Culture) %>%
      summarise(P = sum(Production_Totale_T, na.rm = TRUE))
    plot_ly(d, labels = ~Type_Culture, values = ~P, type = "pie",
            marker = list(colors = pal), textinfo = "label+percent") %>%
      theme_plotly()
  })

  output$p_rende <- renderPlotly({
    d <- coop_f() %>% group_by(Region) %>%
      summarise(R = mean(Rendement_Moyen_T_ha, na.rm = TRUE)) %>% arrange(desc(R))
    plot_ly(d, x = ~reorder(Region, R), y = ~R, type = "bar",
            marker = list(color = pal[2])) %>%
      theme_plotly() %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "T/ha"))
  })

  output$p_top <- renderPlotly({
    d <- coop_f() %>% arrange(desc(Production_Totale_T)) %>% head(10)
    plot_ly(d, x = ~Production_Totale_T, y = ~reorder(Nom_Coop, Production_Totale_T),
            type = "bar", orientation = "h",
            marker = list(color = pal[3])) %>%
      theme_plotly() %>%
      layout(xaxis = list(title = "Tonnes"), yaxis = list(title = ""))
  })

  # =========================================================================
  #  ONGLET EXPORTATIONS
  # =========================================================================
  output$e_pays <- renderPlotly({
    d <- expo_f() %>% group_by(Pays_Destination) %>%
      summarise(V = sum(Valeur_Totale_USD, na.rm = TRUE)) %>% arrange(desc(V))
    plot_ly(d, x = ~V, y = ~reorder(Pays_Destination, V), type = "bar",
            orientation = "h", marker = list(color = pal[4])) %>%
      theme_plotly() %>%
      layout(xaxis = list(title = "USD"), yaxis = list(title = ""))
  })

  output$e_produit <- renderPlotly({
    d <- expo_f() %>% group_by(Type_Produit) %>%
      summarise(V = sum(Valeur_Totale_USD, na.rm = TRUE))
    plot_ly(d, labels = ~Type_Produit, values = ~V, type = "pie",
            marker = list(colors = pal), textinfo = "label+percent") %>%
      theme_plotly()
  })

  output$e_trim <- renderPlotly({
    d <- expo_f() %>% group_by(Trimestre) %>%
      summarise(V = sum(Valeur_Totale_USD, na.rm = TRUE)) %>% arrange(Trimestre)
    plot_ly(d, x = ~Trimestre, y = ~V, type = "bar",
            marker = list(color = pal[6])) %>%
      theme_plotly() %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "USD"))
  })

  output$e_prix <- renderPlotly({
    d <- expo_f() %>% group_by(Annee) %>%
      summarise(P = mean(Prix_Unitaire_USD, na.rm = TRUE))
    plot_ly(d, x = ~Annee, y = ~P, type = "scatter", mode = "lines+markers",
            line = list(color = pal[5], width = 3),
            marker = list(color = pal[5], size = 8)) %>%
      theme_plotly() %>%
      layout(xaxis = list(title = "Campagne", dtick = 1),
             yaxis = list(title = "USD / T"))
  })

  # =========================================================================
  #  ONGLET IMPACT SOCIO-ECONOMIQUE
  # =========================================================================
  output$i_revenu <- renderPlotly({
    d <- impa_f() %>% group_by(Region) %>%
      summarise(R = mean(Revenu_Moyen_Mensuel_FCFA, na.rm = TRUE)) %>% arrange(desc(R))
    plot_ly(d, x = ~reorder(Region, R), y = ~R, type = "bar",
            marker = list(color = pal[2])) %>%
      theme_plotly() %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "FCFA"))
  })

  output$i_emploi <- renderPlotly({
    d <- impa_f() %>% group_by(Region) %>%
      summarise(Directs = sum(Emplois_Directs, na.rm = TRUE),
                Indirects = sum(Emplois_Indirects, na.rm = TRUE))
    plot_ly(d, x = ~Region, y = ~Directs, type = "bar", name = "Directs",
            marker = list(color = pal[1])) %>%
      add_trace(y = ~Indirects, name = "Indirects",
                marker = list(color = pal[2])) %>%
      theme_plotly() %>%
      layout(barmode = "group", xaxis = list(title = ""),
             yaxis = list(title = "Emplois"))
  })

  output$i_scola <- renderPlotly({
    d <- impa_f() %>% group_by(Region) %>%
      summarise(S = mean(Taux_Scolarisation_Pct, na.rm = TRUE)) %>% arrange(desc(S))
    plot_ly(d, x = ~reorder(Region, S), y = ~S, type = "bar",
            marker = list(color = pal[7])) %>%
      theme_plotly() %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "%", range = c(0, 100)))
  })

  output$i_rse <- renderPlotly({
    d <- impa_f() %>% group_by(Region) %>%
      summarise(B = sum(Budget_RSE_FCFA, na.rm = TRUE)) %>% arrange(desc(B))
    plot_ly(d, x = ~reorder(Region, B), y = ~B, type = "bar",
            marker = list(color = pal[8])) %>%
      theme_plotly() %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "FCFA"))
  })

  # =========================================================================
  #  ONGLET DONNEES
  # =========================================================================
  output$table_coop <- renderDT({
    coop_f() %>%
      select(ID_Coop, Nom_Coop, Type_Culture, Region, Departement,
             Superficie_ha, Nb_Producteurs, Production_Totale_T,
             Rendement_Moyen_T_ha, Statut_Certification, Taxes_Versees_FCFA) %>%
      datatable(options = list(pageLength = 10, scrollX = TRUE),
                rownames = FALSE, filter = "top")
  })
}

# =============================================================================
shinyApp(ui, server)
