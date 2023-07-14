const { faker } = require('@faker-js/faker');

// Função auxiliar para gerar uma string formatada para o insert
function formatInsert(table, columns, values) {
  const newValues = values.map(val => {
    const quotes = val.startsWith("'")
    val = val.replaceAll("'", "")
    return quotes ? `'${val}'` : val
  })
  
  return `INSERT INTO ${table} (${columns.join(', ')}) VALUES (${newValues.join(', ')});`;
}

// Gerar inserts para a tabela cliente
function generateClienteInserts(numInserts) {
  const inserts = [];

  for (let i = 0; i < numInserts; i++) {
    const nome = faker.person.fullName();
    const cpf = faker.number.bigInt({ min: 10000000000, max: 99999999999 });
    const cidade_id = faker.number.int({ min: 1, max: 5564 });
    const data_nascimento = faker.date.birthdate().toISOString().split('T')[0];

    const insert = formatInsert('cliente', ['nome', 'cpf', 'cidade_id', 'data_nascimento'], [
      `'${nome}'`,
      `'${cpf}'`,
      `${cidade_id}`,
      `'${data_nascimento}'`
    ]);

    inserts.push(insert);
  }

  return inserts;
}

// Gerar inserts para a tabela loja
function generateLojaInserts(numInserts) {
  const inserts = [];

  for (let i = 0; i < numInserts; i++) {
    const cidade_id = faker.number.int({ min: 1, max: 5564 });
    const data_inauguracao = faker.date.birthdate().toISOString().split('T')[0];

    const insert = formatInsert('loja', ['cidade_id', 'data_inauguracao'], [
      `${cidade_id}`,
      `'${data_inauguracao}'`
    ]);

    inserts.push(insert);
  }

  return inserts;
}

// Gerar inserts para a tabela funcionario
function generateFuncionarioInserts(numInserts) {
  const inserts = [];

  for (let i = 0; i < numInserts; i++) {
    const nome = faker.person.fullName();
    const cpf = faker.number.int({ min: 10000000000, max: 99999999999 });
    const loja_id = faker.number.int({ min: 1, max: 5 });
    const data_nascimento = faker.date.birthdate().toISOString().split('T')[0];

    const insert = formatInsert('funcionario', ['nome', 'cpf', 'loja_id', 'data_nascimento'], [
      `'${nome}'`,
      `'${cpf}'`,
      `${loja_id}`,
      `'${data_nascimento}'`
    ]);

    inserts.push(insert);
  }

  return inserts;
}

// Gerar inserts para a tabela marca
function generateMarcaInserts(numInserts) {
  const inserts = [];

  for (let i = 0; i < numInserts; i++) {
    const nome = faker.company.name();

    const insert = formatInsert('marca', ['nome'], [`'${nome}'`]);
    inserts.push(insert);
  }

  return inserts;
}

// Gerar inserts para a tabela produto
function generateProdutoInserts(numInserts) {
  const inserts = [];

  for (let i = 0; i < numInserts; i++) {
    const nome = faker.commerce.productName();
    const marca_id = faker.number.int({ min: 1, max: 5 });
    const valor = faker.number.int({ min: 10, max: 1000 });

    const insert = formatInsert('produto', ['nome', 'marca_id', 'valor'], [
      `'${nome}'`,
      `${marca_id}`,
      `${valor}`
    ]);

    inserts.push(insert);
  }

  return inserts;
}

// Gerar inserts para a tabela estoque
function generateEstoqueInserts(numInserts) {
  const inserts = [];

  for (let i = 0; i < numInserts; i++) {
    const produto_id = faker.number.int({ min: 1, max: 50 });
    const loja_id = faker.number.int({ min: 1, max: 10 });
    const quant = 10000;

    const insert = formatInsert('estoque', ['produto_id', 'loja_id', 'quant'], [
      `${produto_id}`,
      `${loja_id}`,
      `${quant}`
    ]);

    inserts.push(insert);
  }

  return inserts;
}

// Gerar inserts para a tabela venda
function generateVendaInserts(numInserts) {
  const inserts = [];

  for (let i = 0; i < numInserts; i++) {
    const loja_id = faker.number.int({ min: 1, max: 10 });
    const cliente_id = faker.number.int({ min: 1, max: 100 });
    const funcionario_id = faker.number.int({ min: 1, max: 50 });

    const insert = formatInsert('venda', ['loja_id', 'cliente_id', 'funcionario_id'], [
      `${loja_id}`,
      `${cliente_id}`,
      `${funcionario_id}`
    ]);

    inserts.push(insert);
  }

  return inserts;
}

// Gerar inserts para a tabela item_venda
function generateItemVendaInserts(numInserts) {
  const inserts = [];

  for (let i = 0; i < numInserts; i++) {
    const venda_id = faker.number.int({ min: 1, max: 1000 });
    const produto_id = faker.number.int({ min: 1, max: 50 });
    const quant = faker.number.int({ min: 1, max: 10 });
    const valor = faker.number.int({ min: 10, max: 100 });

    const insert = formatInsert('item_venda', ['venda_id', 'produto_id', 'quant', 'valor'], [
      `${venda_id}`,
      `${produto_id}`,
      `${quant}`,
      `${valor}`
    ]);

    inserts.push(insert);
  }

  return inserts;
}

// Gerar 100 inserts para a tabela cliente
const clienteInserts = generateClienteInserts(100);

// Gerar 20 inserts para a tabela loja
const lojaInserts = generateLojaInserts(20);

// Gerar 50 inserts para a tabela funcionario
const funcionarioInserts = generateFuncionarioInserts(50);

// Gerar 4 inserts para a tabela marca
const marcaInserts = generateMarcaInserts(40);

// Gerar 200 inserts para a tabela produto
const produtoInserts = generateProdutoInserts(200);

// Gerar 500 inserts para a tabela estoque
const estoqueInserts = generateEstoqueInserts(500);

// Gerar 1000 inserts para a tabela venda
const vendaInserts = generateVendaInserts(1000);

// Gerar 2000 inserts para a tabela item_venda
const itemVendaInserts = generateItemVendaInserts(2000);

// Imprimir os inserts gerados
console.log('');
clienteInserts.forEach(insert => console.log(insert));

console.log('');
lojaInserts.forEach(insert => console.log(insert));

console.log('');
funcionarioInserts.forEach(insert => console.log(insert));

console.log('');
marcaInserts.forEach(insert => console.log(insert));

console.log('');
produtoInserts.forEach(insert => console.log(insert));

console.log('');
estoqueInserts.forEach(insert => console.log(insert));

console.log('');
vendaInserts.forEach(insert => console.log(insert));

console.log('');
itemVendaInserts.forEach(insert => console.log(insert));