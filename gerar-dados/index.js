const { faker } = require('@faker-js/faker');

const lojas = 20, produtos = 200, vendas = 1000

function formatInsert(tableName, columns, values) {
  const newValues = values.map(val => {
    if(typeof val !== 'string')
        return val

    const quotes = val.startsWith("'")
    val = val.replaceAll("'", "")
    return quotes ? `'${val}'` : val
  })
  
  return `INSERT INTO ${tableName} (${columns.join(', ')}) VALUES (${newValues.join(', ')});`;
}

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
      cidade_id,
      `'${data_nascimento}'`
    ]);

    inserts.push(insert);
  }

  return inserts;
}

function generateLojaInserts() {
  const inserts = [];

  for (let i = 0; i < lojas; i++) {
    const cidade_id = faker.number.int({ min: 1, max: 5564 });
    const data_inauguracao = faker.date.birthdate().toISOString().split('T')[0];

    const insert = formatInsert('loja', ['cidade_id', 'data_inauguracao'], [
      cidade_id,
      `'${data_inauguracao}'`
    ]);

    inserts.push(insert);
  }

  return inserts;
}

function generateFuncionarioInserts(numInserts) {
  const inserts = [];

  for (let i = 0; i < numInserts; i++) {
    const nome = faker.person.fullName();
    const cpf = faker.number.int({ min: 10000000000, max: 99999999999 });
    const loja_id = faker.number.int({ min: 1, max: lojas });
    const data_nascimento = faker.date.birthdate().toISOString().split('T')[0];

    const insert = formatInsert('funcionario', ['nome', 'cpf', 'loja_id', 'data_nascimento'], [
      `'${nome}'`,
      `'${cpf}'`,
      loja_id,
      `'${data_nascimento}'`
    ]);

    inserts.push(insert);
  }

  return inserts;
}

function generateMarcaInserts(numInserts) {
  const inserts = [];

  for (let i = 0; i < numInserts; i++) {
    const nome = faker.company.name();

    const insert = formatInsert('marca', ['nome'], [`'${nome}'`]);
    inserts.push(insert);
  }

  return inserts;
}

function generateProdutoInserts() {
  const inserts = [];

  for (let i = 0; i < produtos; i++) {
    const nome = faker.commerce.productName();
    const marca_id = faker.number.int({ min: 1, max: 5 });
    const valor = faker.number.int({ min: 10, max: 1000 });

    const insert = formatInsert('produto', ['nome', 'marca_id', 'valor'], [
      `'${nome}'`,
      marca_id,
      valor
    ]);

    inserts.push(insert);
  }

  return inserts;
}

function generateEstoqueInserts() {
  const inserts = [];
  const quant = 10000;

  for (let loja_id = 1; loja_id <= lojas; loja_id++) {
    for (let produto_id = 1; produto_id <= produtos; produto_id++) {
      const insert = formatInsert('estoque', ['produto_id', 'loja_id', 'quant'], [
        produto_id,
        loja_id,
        quant
      ]);

      inserts.push(insert);      
    }
  }

  return inserts;
}

function generateVendaInserts() {
  const inserts = [];

  for (let i = 0; i < vendas; i++) {
    const loja_id = faker.number.int({ min: 1, max: 10 });
    const cliente_id = faker.number.int({ min: 1, max: 100 });
    const funcionario_id = faker.number.int({ min: 1, max: 50 });

    const insert = formatInsert('venda', ['loja_id', 'cliente_id', 'funcionario_id'], [
      loja_id,
      cliente_id,
      funcionario_id
    ]);

    inserts.push(insert);
  }

  return inserts;
}

function generateItemVendaInserts() {
  const inserts = [];

  for (let venda_id = 1; venda_id <= vendas; venda_id++) {
    const totalItens = faker.number.int({ min: 1, max: 8 });
    const produtoIdSet = new Set()
    for (let i = 1; i <= totalItens; i++) {
      const produto_id = faker.number.int({ min: 1, max: produtos });
      produtoIdSet.add(produto_id)
    }

    produtoIdSet.forEach(produto_id => {
      const quant = faker.number.int({ min: 1, max: 10 });
      const valor = faker.number.int({ min: 10, max: 100 });
  
      const insert = formatInsert('item_venda', ['venda_id', 'produto_id', 'quant', 'valor'], [
        venda_id,
        produto_id,
        quant,
        valor
      ]);
  
      inserts.push(insert);  
    })
  }

  return inserts;
}

const clienteInserts = generateClienteInserts(100);
const lojaInserts = generateLojaInserts();
const funcionarioInserts = generateFuncionarioInserts(50);
const marcaInserts = generateMarcaInserts(40);
const produtoInserts = generateProdutoInserts();
const estoqueInserts = generateEstoqueInserts();
const vendaInserts = generateVendaInserts();
const itemVendaInserts = generateItemVendaInserts();

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