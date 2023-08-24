# 1. Você recebeu um repositório git local pronto mas sem um endereço remoto (acho pouco provável)

```
# A. Pode fazer todos os comandos só no final da prova
git remote add origin URL_REPOSITORIO_REMOTO

# B. Adicionar todos os arquivos no repositório git local
git add .

# C. Confirmar as alteracoes no repositório local
# O comando pode dar erro, pedindo pra configurar nome e email. É só seguir as instruções e tentar novamente.
git commit -m "Alteracoes"

# D. Enviar as alterações pro repositório remoto
# Depois de executar, ele pode pedir pra executar o comando de uma forma diferente. É só copiar e colar como ele mostrar
git push 
```

# 2. Você recebeu um projeto em um repositório git local já com o endereço do repositório remoto

Execute todos os passos, a partir do B (pode fazer todos os comandos só no final da prova).

# 3. Você não recebeu um repositório git local na máquina da prova e tem que baixar

## 3.1 Fazer no início da prova
```
# Baixar o projeto pra máquina local no início da prova
# O comando cria uma pasta com o nome que aparece no final da URL e já configura o remote
git clone URL_REPOSITORIO_REMOTO
```

## 3.2 Fazer no final da prova

Execute todos os passos, a partir do B (estes pode fazer só no final da prova).

# 4. Você tem que criar um projeto e repositório git do zero (acho improvável)

## 4.1 Fazer no início da prova

```
# Criar uma pasta para o projeto

# Abrir a pasta no editor/IDE que fornecerem (no VSCode é File >> Open Folder)

# Abrir um terminal, que já deve vir dentro da pasta do projeto que vc abriu

# Criar um repositório local
git init 
```

## 4.2 Fazer no final da prova

- Executar todos os passos, a partir do A 
