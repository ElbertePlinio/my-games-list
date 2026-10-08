# Política de Privacidade

Versão: 2026-06-22

Data de vigência: 22 de junho de 2026

Esta Política de Privacidade descreve como o Picklog ("aplicativo", "serviço", "nós") coleta, usa, compartilha e protege seus dados pessoais, em conformidade com a Lei nº 13.709/2018 (Lei Geral de Proteção de Dados Pessoais, "LGPD"). Ao criar uma conta e utilizar o serviço, você declara estar ciente das práticas descritas aqui.

## 1. Quem é o controlador dos dados

O controlador dos dados pessoais tratados no Picklog é **Elberte Plínio** (pessoa física). O Picklog é mantido por uma pessoa natural, e não por uma empresa; a LGPD (Art. 5º, VI) admite expressamente que o controlador seja pessoa física.

O controlador é a pessoa responsável pelas decisões referentes ao tratamento dos seus dados pessoais.

## 2. Encarregado pelo Tratamento de Dados (DPO)

Para exercer seus direitos ou esclarecer dúvidas sobre o tratamento dos seus dados pessoais, entre em contato com o Encarregado (Data Protection Officer):

- Encarregado (DPO): **Elberte Plínio** — **games@elberte.com**

O Encarregado é o canal de comunicação entre você, o controlador e a Autoridade Nacional de Proteção de Dados (ANPD).

## 3. Quais dados pessoais coletamos

Coletamos apenas os dados necessários para operar o serviço. Não vendemos seus dados pessoais.

Dados de identificação e cadastro:

- Endereço de e-mail.
- Nome de usuário.
- Identificador do provedor de autenticação social (firebase_uid) e o provedor utilizado (e-mail, Google ou Apple), quando você opta por login social.

Dados de autenticação e sessão:

- Senha, armazenada exclusivamente na forma de hash criptográfico (bcrypt); nunca armazenamos a senha em texto puro.
- Tokens de sessão, armazenados na forma de hash (SHA-256), com data de criação, de último acesso e de expiração.

Dados de consentimento:

- A versão dos documentos legais aceitos (consent_version) e a data e hora em que você os aceitou (consent_accepted_at).

Dados de notificações:

- Token de notificação push (fcm_token), quando você ativa notificações no dispositivo.

Dados da sua biblioteca de jogos (dados comportamentais):

- Jogos adicionados à sua biblioteca e o status atribuído a cada um (planejado, jogando, em espera, finalizado, abandonado).
- Nota ou avaliação atribuída ao jogo.
- Tempo de jogo registrado.
- Datas de início e término.
- Dificuldade informada, marcação de favorito e anotações pessoais de texto livre.

Não coletamos intencionalmente dados pessoais sensíveis (como origem racial, convicção religiosa, opinião política, dados de saúde ou biometria). Pedimos que você não inclua esse tipo de informação nas anotações de texto livre.

## 4. Para que usamos seus dados e com qual base legal

Tratamos seus dados pessoais para as finalidades abaixo, sempre amparados em uma base legal da LGPD (Art. 7):

- Criar, autenticar e proteger sua conta. Base legal: execução de contrato (Art. 7, V).
- Armazenar e exibir sua biblioteca de jogos e suas avaliações. Base legal: execução de contrato (Art. 7, V).
- Registrar e comprovar o consentimento que você forneceu aos documentos legais. Base legal: cumprimento de obrigação legal e regulatória (Art. 7, II).
- Enviar notificações push relacionadas ao serviço, quando você as ativa. Base legal: consentimento (Art. 7, I), que pode ser revogado a qualquer momento.
- Garantir a segurança, prevenir fraudes e abusos e operar a infraestrutura. Base legal: legítimo interesse (Art. 7, IX).
- Diagnosticar erros e a estabilidade do serviço por meio de relatórios técnicos. Base legal: consentimento (Art. 7, I). Esses relatórios são enviados ao Firebase Crashlytics apenas mediante o seu consentimento explícito e podem conter contexto técnico da falha (como mensagens de erro, rastreamento de pilha, modelo do dispositivo e versão do aplicativo). Você pode recusar ou revogar esse envio a qualquer momento nas configurações de consentimento.

## 5. Compartilhamento e operadores

Não comercializamos seus dados pessoais. Compartilhamos dados apenas com operadores que os tratam em nosso nome e na medida necessária para o funcionamento do serviço:

- Google e Firebase: utilizados para autenticação (login social com Google e Apple) e para o envio de notificações push (Firebase Cloud Messaging). Quando você usa login social, recebemos do provedor o identificador, o e-mail e o nome associados à conta.
- IGDB (Internet Game Database): utilizado como fonte do catálogo de jogos (nomes, capas, datas de lançamento e plataformas). As consultas ao IGDB referem-se a jogos do catálogo; não enviamos seus dados pessoais ou da sua biblioteca para o IGDB.
- Firebase Crashlytics (Google): utilizado, apenas mediante o seu consentimento explícito, para registrar falhas e erros do aplicativo a fim de diagnosticar a estabilidade do serviço. Os relatórios podem conter contexto técnico da falha.

## 5.1 Recursos opcionais: sugestões com IA e contas de jogos conectadas

RASCUNHO PARA REVISÃO: Esta subseção trata de dois recursos opcionais. O controlador precisa revisá-la e aprová-la antes da publicação.

Sugestões com IA (opcionais e desligadas até você concordar):

- O que o recurso faz: sugere jogos do seu backlog ("Jogar a seguir") e jogos novos que você ainda não tem ("Descobrir com IA").
- Operador: a OpenAI gera as sugestões em nosso nome.
- O que enviamos à OpenAI: os nomes, status, notas, gêneros e tempo de jogo dos jogos da sua biblioteca, além do texto ou pedido opcional que você digitar. Nunca enviamos seu e-mail, seu nome de usuário ou o identificador da sua conta.
- O que guardamos: a data e a hora em que você ativou o recurso e uma contagem diária dos seus pedidos de IA, que usamos para aplicar o limite diário. O Picklog não registra o texto que envia à OpenAI nem as sugestões que recebe.
- Base legal: consentimento (Art. 7, I). Nada é enviado à OpenAI até você aceitar a ativação no aplicativo. Você pode revogar o consentimento a qualquer momento em Configurações, na seção Sugestões com IA. Depois da revogação, o Picklog não envia novos pedidos.

Contas de jogos conectadas (opcionais):

- O que o recurso faz: importa suas conquistas, troféus e tempo de jogo e, se você escolher, adiciona à sua biblioteca os jogos que você tem ou jogou.
- O que você nos informa: apenas um identificador público, como a URL do perfil ou o SteamID da Steam, a gamertag da Xbox, o nome de usuário do RetroAchievements ou o ID online da PlayStation. Nunca pedimos suas senhas ou tokens de sessão desses serviços.
- De onde vêm os dados: Steam (Steam Web API), Xbox (por meio do serviço OpenXBL), RetroAchievements e PlayStation (experimental, apenas listas públicas de troféus). Lemos apenas os dados que o serviço torna públicos no seu perfil.
- O que guardamos: o identificador, o nome de exibição, os links do avatar e do perfil, o status e o horário da sincronização, o progresso e o tempo de jogo por jogo e os dados das conquistas (nomes, descrições, ícones, datas de desbloqueio e raridade).
- Base legal: execução de contrato (Art. 7, V), porque você nos pede para conectar a conta e importar os dados.
- Por quanto tempo guardamos: até você desconectar a conta ou excluir sua conta no Picklog. Ao desconectar, apagamos o progresso e as conquistas importados. Os jogos que a importação adicionou à sua biblioteca continuam lá até você removê-los.

A exportação de dados em Configurações inclui os dados dos dois recursos. A OpenAI e os serviços de jogos acima podem tratar dados fora do Brasil, nos termos do Art. 33 da LGPD.

## 6. Transferência internacional de dados

Alguns operadores (como Google, Firebase e IGDB) podem tratar dados em servidores localizados fora do Brasil. Nesses casos, a transferência internacional ocorre em conformidade com o Art. 33 da LGPD, mediante garantias adequadas de proteção dos dados e limitada às finalidades descritas nesta Política.

## 7. Por quanto tempo guardamos seus dados

- Dados de conta, consentimento e biblioteca: mantidos enquanto sua conta estiver ativa.
- Sessões: mantidas até a expiração do token, até o logout ou até a exclusão da conta.
- Token de notificação push: mantido até ser atualizado, removido por você ou até a exclusão da conta.

Quando você exclui sua conta, os dados associados (conta, sessões e biblioteca) são eliminados de forma definitiva e em cascata. Podemos reter registros estritamente necessários para cumprir obrigação legal ou para o exercício regular de direitos, pelo período exigido pela legislação.

## 8. Seus direitos como titular

Conforme a LGPD (Art. 18), você tem direito a:

- Confirmação da existência de tratamento e acesso aos seus dados.
- Portabilidade e exportação dos seus dados, disponível no aplicativo em Configurações (exportação completa da conta e da biblioteca em formato legível por máquina).
- Correção de dados incompletos, inexatos ou desatualizados.
- Eliminação dos seus dados e exclusão da conta, disponível no aplicativo em Configurações (exclusão definitiva e em cascata).
- Revogação do consentimento. Você pode desativar as notificações push a qualquer momento. Como o registro de consentimento aos documentos legais está vinculado à existência da conta, a forma de revogar esse consentimento de modo amplo é excluir a conta.
- Sair a qualquer momento por meio do logout. Ao sair, removemos suas credenciais deste dispositivo (apagamos o token armazenado e limpamos o cabeçalho de autenticação); o token de acesso expira no servidor após o seu período de validade.
- Informação sobre as entidades com as quais compartilhamos dados, conforme descrito nesta Política.

Para exercer qualquer direito que não esteja disponível diretamente no aplicativo, entre em contato com o Encarregado indicado na seção 2.

## 9. Como protegemos seus dados

Adotamos medidas técnicas e administrativas para proteger seus dados, incluindo:

- Tráfego protegido por TLS (HTTPS) em produção.
- Senhas armazenadas apenas como hash bcrypt.
- Tokens de sessão armazenados apenas como hash SHA-256; o token original nunca é gravado em nossos servidores.
- Tokens de acesso assinados (JWT) com expiração e validação de sessão.
- Cabeçalhos de segurança HTTP, limitação de taxa de requisições e tempos de expiração de requisições.
- Conexão com o banco de dados protegida por TLS em produção.

Nenhum sistema é completamente imune a riscos; trabalhamos continuamente para mitigá-los.

## 10. Cookies e identificadores

O aplicativo não utiliza cookies de publicidade nem rastreadores de terceiros. Utilizamos identificadores estritamente técnicos e necessários, como tokens de autenticação e o token de notificação push, para operar o serviço.

## 11. Dados de crianças e adolescentes

O serviço não é destinado a menores de 18 anos sem o consentimento e a supervisão dos pais ou responsáveis legais. Não coletamos intencionalmente dados de crianças. Se identificarmos que coletamos dados de uma criança sem a devida autorização, eliminaremos essas informações. Caso seja responsável por um menor e acredite que ele nos forneceu dados, entre em contato com o Encarregado.

## 12. Alterações nesta Política

Podemos atualizar esta Política de Privacidade para refletir mudanças no serviço ou na legislação. Quando a alteração for material, atualizaremos a versão e a data de vigência indicadas acima e solicitaremos um novo aceite no aplicativo, registrando a versão aceita. Recomendamos a revisão periódica deste documento.

## 13. Contato

Para dúvidas, solicitações ou reclamações sobre o tratamento dos seus dados pessoais, contate o Encarregado indicado na seção 2. Você também tem o direito de peticionar perante a Autoridade Nacional de Proteção de Dados (ANPD).
