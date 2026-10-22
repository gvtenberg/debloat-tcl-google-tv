# Debloat de TV TCL com Google TV (Android TV 11), sem root

Guia em português para deixar uma TV TCL com Google TV **mais rápida, sem propaganda e sem apps inúteis**, usando só um computador na mesma rede Wi-Fi. **Não precisa de root**, não apaga nada da TV e **tudo é reversível**.

O trabalho foi feito com a ajuda do [Claude Code](https://claude.com/claude-code). No fim deste guia há os prompts usados, para você repetir o processo na sua TV, mesmo que seja de outra marca.

> ⚠️ **Aviso:** você faz isso por sua conta e risco. Os comandos aqui só *desativam* apps (o que se desfaz com um comando), mas cada TV é diferente. Leia antes de rodar.

---

## 📺 TV usada neste guia

| Item | Valor |
|---|---|
| Marca | TCL |
| Sistema | Google TV, **Android TV 11** (API 30) |
| Build do SO | `RP1A.200622.001 release-keys` |
| Firmware (Informações do produto) | `V8-R51MT05-LF1V652` |
| Nome do produto / dispositivo | `G03_4K_GB` / `BeyondTV4` |
| Linha / plataforma | `2021RT51MUHDGTV`, chip **Realtek RTD288O** (`rtd288o`) |
| Memória RAM | 2 GB |
| Arquitetura | **32 bits** (`armeabi-v7a`) |
| Controle remoto | TCL RC902V (Bluetooth, com microfone) |
| Patch de segurança | 5 de dezembro de 2024 |

Você encontra esses dados em **Configurações > Sistema > Sobre**. Pelo computador, com o ADB conectado:
```bash
adb shell getprop ro.product.brand        # marca
adb shell getprop ro.build.fingerprint    # build completo
adb shell getprop ro.board.platform       # chip
adb shell getprop ro.product.cpu.abi      # arquitetura (armeabi-v7a = 32 bits)
```

## 📊 Resultado

| | Antes | Depois |
|---|---|---|
| Memória livre com a TV parada | ~370 MB | **~555 MB** (+50%) |
| Tela inicial | Google TV com recomendações e anúncios | [LTvLauncher](https://github.com/leanbitlab-org/LtvLauncher), limpo e open source |
| Apps desativados | 4 | 32 |
| Atualização automática de firmware TCL | ligada | desligada |

**Continua funcionando:** TV por antena, entradas HDMI, SmartTube, Jellyfin, Netflix, Prime Video, HBO Max, Aurora Store, X-plore, TV Bro, pesquisa por voz (inclusive dentro do SmartTube), Chromecast, proteção de tela "Ambiente" e TCL Channel. Na Etapa 2, os botões **YouTube** e **TCL Channel** do controle passam a abrir o SmartTube e o app TV.

**Efeito colateral conhecido:** o botão de **Configurações** (engrenagem) do controle para de funcionar, porque quem o tratava era o launcher do Google TV. Abra as configurações pelo ícone do LTvLauncher.

---

## 🧰 O que você precisa

- Um computador com **Linux** (usei o Zorin OS 18, baseado em Ubuntu). No Windows/macOS os comandos `adb` são os mesmos, mas os scripts `.sh` precisam de Linux, macOS ou WSL.
- O computador e a TV **na mesma rede**.
- O **ADB** (Android Debug Bridge), uma ferramenta open source do Android:
  ```bash
  sudo apt install adb
  ```
- O controle da TV na mão: na primeira conexão, a TV pede autorização na tela.

> 💡 **Usa Pi-hole/AdGuard?** O download do launcher vem do GitHub. Se algo não baixar, desative o bloqueio temporariamente.

---

## 🪜 Passo a passo

### 1. Ativar o modo desenvolvedor e a depuração na TV
1. Na TV: **Configurações > Sistema > Sobre**.
2. Clique **7 vezes** em **"Build do SO do Android TV"** até aparecer "Você agora é um desenvolvedor".
3. Volte para **Configurações > Sistema > Opções do desenvolvedor** e ative **Depuração USB**. Se aparecer, ative também **Depuração de rede/ADB pela rede**.
4. Descubra o IP da TV em **Configurações > Rede e Internet** (clique na sua rede Wi-Fi). Exemplo: `192.168.1.50`.

### 2. Conectar o computador à TV
```bash
adb connect 192.168.1.50:5555
```
Na TV vai aparecer **"Permitir depuração?"**: marque **"Sempre permitir deste computador"** e selecione **OK**. Seja rápido, porque a janela some se você mexer em outra coisa. Se sumir, rode `adb disconnect` e `adb connect` de novo.

Confira:
```bash
adb devices -l     # deve mostrar "device" (e não "unauthorized")
```

### 3. Baixar este repositório
```bash
git clone https://github.com/gvtenberg/debloat-tcl-google-tv.git
cd debloat-tcl-google-tv
export TV_IP=192.168.1.50     # troque pelo IP da SUA TV
```

### 4. Fazer backup do estado atual (não altera nada)
```bash
./scripts/backup.sh
```
Salva em `backup/<data-hora>/` a lista de apps, as configurações e o uso de memória. Essa pasta fica fora do Git.

### 5. Fase 1: desativar propaganda, telemetria e apps inúteis
**Antes, abra [`listas/fase1-debloat.txt`](listas/fase1-debloat.txt)** e coloque `#` no começo da linha de qualquer app que **você usa**. Exemplos: o Spotify, ou o espelhamento de tela Miracast/T-Cast.
```bash
./scripts/debloat.sh listas/fase1-debloat.txt
```

O que é desativado, em resumo:
- **TCL, propaganda e telemetria:** vitrine de apps, feed de conteúdo, "adesivos" promocionais, mensagens promocionais, telemetria (`com.tcl.bi`), coleta de logs, T-Guard e o **atualizador de firmware** (cada atualização trazia mais anúncios).
- **TCL, recursos pouco usados:** Alexa, barra de jogos, assistente auditivo, manual eletrônico, navegador, galeria, player de pendrive, Miracast, T-Cast e multitela.
- **Google/Android:** instalador automático de apps de parceiros (`gtvpai`), configuração pelo celular, feedback, TalkBack, SMS, câmera e impressão.
- **Terceiros:** Spotify.

> ❗ **Não desative `com.google.android.tv.remote.service`.** O nome engana: além do controle pelo celular, ele cuida do **microfone do controle Bluetooth**. Sem ele, a pesquisa por voz abre mas fica "muda".

**Teste a TV** (antena, HDMI, seus apps, voz) antes de seguir. Para reiniciar a TV pelo computador:
```bash
adb reboot
```

### 6. Fase 2: trocar a tela inicial por um launcher open source
O launcher do Google TV (`launcherx`) é o que mostra recomendações e anúncios e o que mais consome RAM (~155 MB). Vamos trocá-lo pelo **[LTvLauncher](https://github.com/leanbitlab-org/LtvLauncher)**: open source (GPL-3.0), grátis e sem anúncios.

O script baixa o APK **direto da release oficial no GitHub**, confere o SHA-256 publicado pelo GitHub e instala:
```bash
./scripts/instalar-launcher.sh              # detecta a arquitetura da TV sozinho
./scripts/debloat.sh listas/fase2-launcher.txt
```
A segunda linha desativa o launcher do Google TV e o assistente de configuração (`setupwraith`). Se ficasse ativo, ele assumiria a tela inicial no lugar do novo launcher.

Aperte **Home** no controle: deve abrir o LTvLauncher. Organize os favoritos pela engrenagem do launcher. **Não precisa conceder** as permissões extras que ele oferece (acessibilidade, notificações, sobreposição) para o uso básico.

### 7. Reiniciar e testar tudo
```bash
adb reboot
```

### 8. Etapa 2: botões YouTube e TCL Channel do controle
Depois do debloat, os botões **YouTube** e **TCL Channel** do controle param de fazer qualquer coisa:
- O sistema da TCL (`TclPhoneWindowManager`) tem o YouTube oficial (`com.google.android.youtube.tv`) **fixo no código**. Sem ele instalado, o botão não faz nada.
- O botão TCL Channel chamava o app `com.tcl.partnercustomizer`, que também foi removido.

A solução é o **[Key Mapper](https://github.com/keymapperorg/KeyMapper)** (open source, GPL-3.0, versão FOSS). Ele usa um serviço de acessibilidade para "pegar" a tecla **antes** do sistema da TCL e abrir o app que você escolher. Usa ~15 MB de RAM.

**1. Instalar e ativar pelo computador:**
```bash
./scripts/instalar-keymapper.sh
```
O script baixa o APK do GitHub, confere o SHA-256, instala e:
- ativa o serviço de acessibilidade do Key Mapper;
- coloca o app na lista de exceções da economia de energia;
- 🔴 **[TCL] concede a permissão `APP_AUTO_START`.** Sem ela, o bloqueador de inicialização da TCL (`TclAppBoot`) impede o Key Mapper de iniciar depois de reiniciar a TV, e os botões param de funcionar a cada boot. É por isso que remapeadores como o "Home Button" costumam "não funcionar" nas TVs TCL.

**2. Criar os mapeamentos na TV, com o controle.** Cada botão precisa do **seu próprio** mapa de teclas. Se você colocar dois botões no mesmo mapa, o Key Mapper entende "apertar os dois juntos".
1. Abra o **Key Mapper** e selecione **"+ Novo mapa de teclas"**.
2. **"Toque para gravar o gatilho"** e aperte o botão **YouTube**. Deve aparecer **"Código-chave 4065"**.
3. **"Adicionar ação"** → **"Iniciar aplicativo"** → **SmartTube**.
4. Salve pela **seta ←** no canto inferior esquerdo.
5. De volta à tela inicial do Key Mapper, selecione **"+"** de novo para criar o **segundo** mapa: grave o botão **TCL Channel** (**"Código-chave 4020"**) → **"Iniciar aplicativo"** → **TV**.
6. Salve. A tela inicial do Key Mapper deve mostrar **dois cartões separados**.

> Os códigos 4065 (YouTube) e 4020 (TCL Channel) são deste controle (TCL RC902V). Em outros controles podem ser diferentes; o Key Mapper mostra o código ao gravar.

**Para desfazer:** `./scripts/remover-keymapper.sh`

### 9. Etapa 3: teclado de tela com Home Assistant (ou app de controle no celular)
**Sintoma:** com o Home Assistant ligado, o teclado não aparece na tela ao clicar num campo de texto (pesquisa do SmartTube, endereço do navegador etc.).

**Causa:** a integração **"Android TV Remote"** do Home Assistant usa o mesmo protocolo do app de controle remoto do celular (porta 6466). Enquanto há um "controle pelo celular" conectado, o Google TV troca o teclado da TV por um **teclado-ponte** (`ImeBridgeService`), que manda a digitação para o celular. Como o HA fica conectado o tempo todo, o teclado de tela some para sempre. Desabilitar só a ponte **não basta**: na próxima reconexão do HA, o `tv.remote.service` a impõe de novo. E o `tv.remote.service` não pode ser desativado, porque cuida do microfone do controle.

**Solução:**
1. **No Home Assistant**, troque a integração **Android TV Remote** pela **Android Debug Bridge** (ADB), que já vem no HA e não mexe no teclado:
   - **Configurações > Dispositivos e serviços > + Adicionar integração > Android Debug Bridge**.
   - **Host:** o IP da TV. **Porta:** `5555`. Deixe a chave ADB e o servidor ADB **em branco**.
   - Na TV, aceite **"Permitir depuração?"** marcando **"Sempre permitir deste computador"**.
   - Nas opções da integração, desative a captura de tela (screencap) como imagem, para não pesar na TV.
   - Teste a nova entidade (estado, app aberto em `app_id`, volume). Teclas são enviadas pela ação `androidtv.adb_command` (ex.: `HOME`, `BACK`, `UP`).
   - **Desative** (não exclua) a integração **Android TV Remote** e atualize automações e painéis para a nova entidade.
2. **No computador**, deixe o Gboard como teclado padrão e desabilite a ponte:
   ```bash
   ./scripts/teclado-gboard.sh
   ```
3. Reinicie a TV (`adb reboot`) e confira se o teclado aparece.

**Para desfazer:** `./scripts/teclado-gboard.sh reverter` e reative a integração Android TV Remote no HA.

---

## ↩️ Como desfazer

Cada fase se desfaz com o mesmo arquivo de lista:
```bash
./scripts/reverter.sh listas/fase2-launcher.txt   # volta o launcher do Google TV
./scripts/reverter.sh listas/fase1-debloat.txt    # reativa os apps da Fase 1
```
Para reativar **só um app**:
```bash
adb shell pm enable com.tcl.miracast
```
Para remover o LTvLauncher (faça isso **depois** de reverter a Fase 2, senão a TV fica sem tela inicial):
```bash
adb uninstall com.leanbitlab.ltvL
```

---

## ❓ Perguntas frequentes

**A inicialização ainda é lenta. Dá para melhorar?**
Pouco. Medindo pelo log, o Android leva ~23 s só para carregar o sistema, antes de qualquer app, e isso não muda sem root. O debloat tira ~30 apps da inicialização, e o launcher leve aparece e responde mais rápido. A TCL tem a opção **Configurações > Sistema > Energia > Iniciar rápido**, que liga em poucos segundos porque deixa a TV em espera com o sistema na RAM. **Neste guia ela ficou desligada**: em espera, a TV ficava enviando dados pela rede o tempo todo (visto no Pi-hole). Desligar na tomada ou no filtro de linha sempre força a inicialização completa.

**Por que desativar e não desinstalar?**
`pm disable-user` é reversível com um comando e não mexe na partição do sistema. Se algum app não aceitar ser desativado, o script usa `pm uninstall -k --user 0`, que também é reversível (`cmd package install-existing <pacote>`).

**Uma atualização da TV vai desfazer tudo?**
Pode reativar apps. Por isso o atualizador da TCL (`com.tcl.versionUpdateApp`) fica desativado. Se quiser atualizar algum dia, reative-o, atualize e rode os scripts de novo.

**E o YouTube e a Play Store?**
Nesta TV eles já tinham sido removidos antes (`pm uninstall --user 0`). No lugar entraram o [SmartTube](https://github.com/yuliskov/SmartTube) e a [Aurora Store](https://gitlab.com/AuroraOSS/AuroraStore). Isso não faz parte dos scripts; é opcional.

---

## 💬 Prompts usados (para repetir com o Claude Code)

Rode o [Claude Code](https://claude.com/claude-code) **numa pasta vazia** do computador, com a foto da tela "Sobre" da sua TV dentro dela. Troque os dados entre `<>`.

**Legenda:** 🌐 serve para qualquer Android TV / Google TV · 🔵 específico do **Google TV** · 🔴 específico da **TCL** / deste modelo

1. 🌐 **Prompt inicial (debloat completo):**
   > Identifique a TV conectada no mesmo wifi que meu computador (IP da TV: `<IP>`). A TV é minha e está com atualizações pendentes, porque a cada atualização ela veio com mais anúncios e ficou mais lenta. Ela veio com várias propagandas e aplicativos que não uso e que não consigo remover pelo menu. Quero a TV rápida, com tela clean, sem propaganda, sem aplicativos inúteis, e debloated. Faça isso usando este computador e me guie pelo passo a passo. Se tiver dúvidas, pergunte antes de prosseguir. Todas as modificações precisam ser reversíveis. Coloquei a foto das configurações da TV na pasta (arquivo `<foto>.jpg`) para você identificar marca, modelo e sistema. Não instale aplicativos sem minha permissão expressa no chat; prefira apps open source e grátis, instalados direto dos repositórios oficiais (GitHub, por exemplo). `<Uso Pi-hole, me avise se alguma conexão for bloqueada.>` No dia a dia uso: `<lista de apps>`. Ocasionalmente uso: `<lista de apps>`. Não digite senhas nem faça logins ou assinaturas por mim. Se precisar de alguma intervenção na TV, me diga exatamente como fazer.

2. 🔵 **Quando a pesquisa por voz parar de funcionar num app:**
   > O microfone não funcionou no app `<SmartTube>`: abre, mas não acontece nada depois de falar, como se estivesse mudo. Funcionava antes destas mudanças. Investigue pelo log da TV enquanto eu testo.

   *(Aqui a causa era o `com.google.android.tv.remote.service`. Isso vale para Google TV, mas como o controle se conecta ao microfone depende da marca.)*

3. 🔵 **Para trocar a tela inicial:**
   > Quero um launcher open source no lugar da tela inicial do Google TV. Pesquise opções no GitHub, me mostre o repositório, a licença e o APK exato para a arquitetura da minha TV, e só instale depois que eu aprovar.

4. 🔴 **Sobre a inicialização lenta:**
   > A inicialização está muito lenta (do botão de ligar até a tela inicial aparecer). Meça pelo log onde está a demora e me diga o que dá e o que não dá para melhorar sem root.

   *(A opção "Iniciar rápido" e o atraso dos apps no boot, "tboost", são coisas da TCL.)*

5. 🌐 **Para reiniciar sem o controle:**
   > Quando precisar reiniciar a TV, reinicie pelo computador.

6. 🔴 **Para remapear botões do controle:**
   > Quero que o botão YouTube do controle abra o SmartTube e que o botão TCL Channel abra o app TV. Hoje nenhum dos dois abre nada. Descubra pelo log qual código cada botão envia e quem o trata, e me sugira um app open source para remapear (só instale com minha permissão). Depois reinicie a TV e confirme que continua funcionando.

   *(As teclas tratadas no `TclPhoneWindowManager` e o bloqueio `APP_AUTO_START` são da TCL. A ideia de usar um remapeador por acessibilidade vale para qualquer Android TV.)*

7. 🔵 **Para o teclado sumir com o Home Assistant:**
   > Quero fazer o teclado do Google funcionar quando o Home Assistant está ativo. Hoje, com ele ligado, não aparece teclado na tela. Investigue a causa e me dê sugestões antes de mudar algo.

   *(O teclado-ponte `ImeBridgeService` e a integração Android TV Remote afetam qualquer Google TV ou Android TV com o "Android TV Remote Service", de qualquer marca.)*

> ℹ️ **O que é específico de quê:**
> - **Qualquer Android TV:** ADB pela rede, backup, `pm disable-user`, scripts de reversão.
> - **Google TV:** `launcherx`, `setupwraith`, `dreamx`, `gtvpai`, `tv.remote.service` e a necessidade de desativar o launcher para trocá-lo (o Google TV ignora o "launcher padrão").
> - **TCL:** todos os pacotes `com.tcl.*` em [`listas/fase1-debloat.txt`](listas/fase1-debloat.txt), o menu Energia > Iniciar rápido, os códigos de tecla 4065/4020 e a permissão `APP_AUTO_START`.
> - **Este modelo (Realtek RT51M, 32 bits):** o APK `armeabi-v7a` do launcher. TVs com chip 64 bits usam `arm64-v8a`.
>
> Em outra marca (Samsung não é Android; Philips, Sony, Xiaomi, etc. são), use o prompt 1: o Claude lista os apps da *sua* TV e monta uma lista própria.

---

## 📁 Estrutura

```
listas/fase1-debloat.txt     apps desativados na Fase 1 (com descrição de cada um)
listas/fase2-launcher.txt    launcher do Google TV e assistente de configuração
scripts/backup.sh            salva o estado da TV (somente leitura)
scripts/debloat.sh           desativa os apps de uma lista
scripts/reverter.sh          reativa os apps de uma lista
scripts/instalar-launcher.sh baixa (GitHub oficial), confere e instala o LTvLauncher
scripts/instalar-keymapper.sh baixa, confere, instala e ativa o Key Mapper (botões do controle)
scripts/remover-keymapper.sh desfaz a instalação do Key Mapper
scripts/teclado-gboard.sh    Gboard como teclado padrão e desliga o teclado-ponte ("reverter" desfaz)
scripts/comum.sh             funções compartilhadas pelos scripts
```

Os scripts esperam a variável `TV_IP` (`export TV_IP=192.168.1.50`).
