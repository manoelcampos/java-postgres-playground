1. Receber um repositório git local pronto mas sem um endereço remoto

# A. Pode fazer todos os comandos só no final da prova
git remote add origin URL_REPOSITORIO_REMOTO

# B. Adicionar todos os arquivos no repositório git local
git add .

# C. Confirmar as alteracoes no repositório local
git commit -m "Alteracoes"

# Enviar as alterações pro repositório remoto
git push 

2. Receber o repositório git local já com o endereço do repositório remoto

Executar todos os passos, a partir do B
(Pode fazer todos os comandos só no final da prova)

3. Você não recebeu um repositório git local na máquina da prova e tem que baixar

# Baixar o projeto pra máquina local no início da prova (já configurando o remote)
git clone URL_REPOSITORIO_REMOTO

Executar todos os passos, a partir do B (estes pode fazer só no final da prova)

4. Você tem que criar um projeto e repositório git do zero

# Fazer no início da prova
## Criar uma pasta para o projeto
## Precisa abrir a pasta no editor/IDE que fornecerem 
  (no VSCode é File >> Open Folder)

## Abrir um terminal, que já deve vir dentro da pasta do projeto que vc abriu

## Criar um repositório local 
git init 

# Fazer no final da prova

## Executar todos os passos, a partir do A 