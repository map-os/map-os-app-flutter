# Design - Correcoes e Aprimoramentos

## Paleta Unificada ✅

```
primary:       0xFF333649  (navy escuro — base da marca)
accent:        0xFFF3742F  (laranja — unificar todos os orange)
surface:       0xFFF6EFF8  (lavanda claro — AppBar light)
cardDark:      0xFF181824  (dialogos/destaques)
navBar:        0xFF343E77  (barra navegacao inferior)
textLight:     0xFFE3EBF9  (texto sobre fundo escuro)
textMuted:     0xFF555555  (texto secundario)
divider:       0xFF55596E  (divisores)
appBarView:    0xFFFCF5FD  (view pages AppBar)
```

### Cores eliminadas (duplicatas) ✅
| Cor substituida | Por | Arquivos afetados |
|-----------------|-----|-------------------|
| `0xFF36374E` / `0xFF36384D` | `primary` | clients_edit, detalhes_tab, descontos_tab, os_edit |
| `0xFFF1732F` | `accent` | login settings border |
| `0xFFED712D` | `accent` | login warning icon |
| `0xFFFF7E15` | `accent` | botao Editar (5 view pages) |
| `0xFFFC7504` | `accent` | os_edit TabBar selected |
| `0xFFFD6E03` | `accent` | os_edit NavigationRail selected |
| `0xFFF3742F` | `accent` | tutorial, login btn |
| `0xFFE1BEE7` | `surface` | products_add AppBar |
| `0xFFFAF3FB` | `surface` | services_edit AppBar |
| `0xFFFDFDFF` | surface/tema | listPage AppBar |

### Cores por tab (bottom nav) ✅
```
tabProdutos:   0xFFF8B02A  (dourado)
tabServicos:   0xFF2CC4C4  (teal)
tabHome:       Colors.white
tabClientes:   0xFF32A7F4  (azul)
tabOS:         0xFFFB6986  (rosa)
```

### Status colors — unificado ✅
Mapa compartilhado em `lib/theme/app_status_colors.dart` com suporte a cedilha e sem cedilha.

## Tipografia ✅
Arquivo: `lib/theme/app_typography.dart`
- h1 = 22/w700, h2 = 20/w600, body = 16/w400, small = 14/w400, caption = 12/w400
- Aplicado em: os_page, os_add, os_view, clients_add/edit/view, products_add/edit/view, services_add/edit/view, chamados_add/view, dashboard

## Espacamento ✅
Arquivo: `lib/theme/app_spacing.dart`
- xs=4, sm=8, md=16, lg=20, xl=24 + atalhos EdgeInsets

## Componentes Padronizados ✅
- Card: elevation 2, radius 12, padding md, margin sm
- Botao Primario: bg primary, radius 10, size 350x56
- Botao Accent: bg accent, radius 10
- Botao Perigo: bg red, radius 10
- Input: radius 10, contentPadding h16 v12
- AppBar: list=tema, add=surface, view=appBarView, edit=primary
- Status Badge: radius 12, fontSize 12-14 bold white
- Divider: height 30, color divider
- Shimmer: AppColors.shimmerBase/shimmerHighlight
- Toast: SnackBar com behavior: floating

## Bugs Visuais Corrigidos ✅

1. ✅ detalhes_tab — toast de erro trocado de `Colors.green` para `Colors.red`
2. ✅ os_view_page — "exluida"/"exluir" corrigido para "excluida"/"excluir"
3. ✅ clients_view_page — "exluir" corrigido para "excluir"
4. ✅ Status "Orcamento" → "Orçamento" nos dropdowns (os_add, chamados_add, chamados_page)
5. ✅ os_view_page empty services card elevation 8 → 2
6. ✅ login_page — credenciais hardcoded removidas
7. ✅ Cards com `color: Colors.white` removidos em todas list pages
8. ✅ listPage AppBar `0xFFFDFDFF` removido (usa tema)
9. ✅ Fluttertoast padronizado para SnackBar com behavior: floating
10. ✅ Status colors unificados em AppStatusColors (OS + Chamados)
11. ✅ clients_view_page dividers padronizados
12. ✅ products_add AppBar roxo → surface
13. ✅ services_add AppBar dark navy → surface
14. ✅ services_edit AppBar → surface
15. ✅ clients_edit btn → primary, radius 10
16. ✅ detalhes_tab/descontos_tab btn → primary, radius 10
17. ✅ os_edit NavigationRail/TabBar → primary/accent
18. ✅ produtos_tab/servicos_tab decrement btn → Colors.red

## Arquivos Criados
- `lib/theme/app_colors.dart` — constantes de cor
- `lib/theme/app_typography.dart` — textTheme padronizado
- `lib/theme/app_spacing.dart` — constantes de espacamento
- `lib/theme/app_status_colors.dart` — mapa de status colors compartilhado

## Arquivos Modificados
- `lib/main.dart` — ThemeData com paleta unificada
- `lib/pages/os/os_page.dart`, `os_add_page.dart`, `os_edit_page.dart`, `os_view_page.dart`
- `lib/pages/os/tabs/detalhes_tab.dart`, `descontos_tab.dart`, `produtos_tab.dart`, `servicos_tab.dart`, `anexos_tab.dart`, `anotacoes_tab.dart`
- `lib/pages/clients/clients_page.dart`, `clients_add_page.dart`, `clients_edit_page.dart`, `clients_view_page.dart`
- `lib/pages/products/products_page.dart`, `products_add_page.dart`, `products_edit_page.dart`, `products_view_page.dart`
- `lib/pages/services/services_page.dart`, `services_add_page.dart`, `services_edit_page.dart`, `services_view_page.dart`
- `lib/pages/chamados/chamados_page.dart`, `chamados_add_page.dart`, `chamados_view_page.dart`
- `lib/pages/dashboard/dashboard_page.dart`
- `lib/pages/login/login_page.dart`
- `lib/pages/listPage.dart`, `about.dart`
- `lib/widgets/TutorialWidget.dart`, `bottom_nav_menu.dart`, `calendar_widget.dart`, `dashboard_status_widget.dart`

## Dark Mode (pendente)
- ThemeData com lightTheme/darkTheme configurado em main.dart
- Cores hardcoded substituidas por AppColors (respeitam tema futuro)
- Para ativar dark mode completo: substituir AppColors.primary/accent por Theme.of(context).colorScheme