-- Script PostgreSQL com cadastro de cidades e estados do país, conforme IBGE.
-- Adaptado de https://www.ricardoarrigoni.com.br/cidades-brasil-lista-de-cidades-brasileiras-em-sql/
-- Área por estado: https://pt.wikipedia.org/wiki/Lista_de_unidades_federativas_do_Brasil_por_área
-- População por estado (prévio censo 2022): https://pt.wikipedia.org/wiki/Lista_de_unidades_federativas_do_Brasil_por_população

drop table if exists item_venda;
drop table if exists venda;

drop table if exists cliente;
drop table if exists funcionario;
drop table if exists estoque;
drop table if exists produto;
drop table if exists marca;

drop table if exists loja;
drop table if exists cidade;
drop table if exists estado;
drop table if exists regiao_geografica;

CREATE TABLE regiao_geografica (
    id serial PRIMARY KEY NOT NULL,
    nome varchar(75) NOT NULL
);

CREATE UNIQUE INDEX ix_regiao ON regiao_geografica (nome);

CREATE TABLE estado (
    id serial PRIMARY KEY NOT NULL,
    nome varchar(75) NOT NULL,
    uf varchar(2) NOT NULL,
    regiao_id int NOT NULL,
    area_km2 int NOT NULL default 0,
    populacao int NOT NULL default 0,
    constraint fk_estado_regiao foreign key (regiao_id) references regiao_geografica(id)
);

CREATE UNIQUE INDEX ix_estado ON estado (nome);
CREATE UNIQUE INDEX ix_uf ON estado (uf);

CREATE TABLE cidade (
    id serial PRIMARY KEY NOT NULL,
    nome varchar(120) NOT NULL,
    estado_id int NOT NULL,
    capital boolean not null default false,
    constraint fk_cidade_estado foreign key (estado_id) references estado(id)
);

CREATE UNIQUE INDEX ix_cidade ON cidade (nome, estado_id);

create table cliente (
    id serial primary key not null,
    nome varchar(75) not null,
    cpf varchar(11) not null,
    cidade_id int not null,
    data_nascimento date not null,
    constraint fk_cliente_cidade foreign key (cidade_id) references cidade(id)
);

create unique INDEX ix_cpf_cliente on cliente (cpf);

create table loja (
    id serial primary key not null,
    cidade_id int not null,
    data_inauguracao date not null,
    constraint fk_loja_cidade foreign key (cidade_id) references cidade(id)
);


create table funcionario (
    id serial primary key not null,
    nome varchar(75) not null,
    cpf varchar(11) not null,
    loja_id int not null,
    data_nascimento date not null,
    constraint fk_funcionario_loja foreign key (loja_id) references loja(id)
);

create unique INDEX ix_cpf_funcionario on funcionario (cpf);

create table marca (
    id serial primary key not null,
    nome varchar(200) not null
);

create unique INDEX ix_marca on marca (nome);

create table produto (
    id serial primary key not null,
    nome varchar(200) not null,
    marca_id int not null,
    valor decimal(10,2) not null,
    constraint fk_produto_marca foreign key (marca_id) references marca(id)
);

create table estoque (
    produto_id int not null,
    loja_id int not null,
    quant int not null,
    primary key (produto_id, loja_id),
    constraint fk_estoque_produto foreign key (produto_id) references produto(id) on delete cascade,
    constraint fk_estoque_loja foreign key (loja_id) references loja(id)
);

create table venda(
    id serial primary key not null,
    loja_id int not null,
    cliente_id int not null,
    funcionario_id int not null,
    data_cadastro timestamp not null default current_timestamp,
    constraint fk_venda_loja foreign key (loja_id) references loja(id),
    constraint fk_venda_cliente foreign key (cliente_id) references cliente(id),
    constraint fk_venda_funcionario foreign key (funcionario_id) references funcionario(id)
);

create table item_venda(
    venda_id int not null,
    produto_id int not null,
    quant int not null,
    valor decimal(10,2) not null,
    primary key (venda_id, produto_id),
    constraint fk_itemvenda_venda foreign key (venda_id) references venda(id) on delete cascade,
    constraint fk_itemvenda_produto foreign key (produto_id) references produto(id)
);


CREATE OR REPLACE FUNCTION diminui_estoque_func()
RETURNS trigger AS $$
BEGIN
    update estoque set quant = quant - new.quant 
    where produto_id = new.produto_id
    and estoque.loja_id = (select v.loja_id from venda v where v.id = new.venda_id);
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION devolve_estoque_func()
RETURNS trigger AS $$
BEGIN
    update estoque set quant = quant + old.quant
    where produto_id = old.produto_id
    and estoque.loja_id = (select v.loja_id from venda v where v.id = old.venda_id);
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION atualiza_estoque_func()
RETURNS trigger AS $$
BEGIN
    update estoque set quant = quant + old.quant - new.quant
    where produto_id = new.produto_id
    and loja_id = (select v.loja_id from venda v where v.id = new.venda_id);
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';


CREATE TRIGGER diminui_estoque_trigger
AFTER INSERT ON item_venda
FOR EACH ROW EXECUTE PROCEDURE diminui_estoque_func();

CREATE TRIGGER devolve_estoque_trigger
AFTER DELETE ON item_venda
FOR EACH ROW EXECUTE PROCEDURE devolve_estoque_func();

CREATE TRIGGER atualiza_estoque_trigger
AFTER UPDATE ON item_venda
FOR EACH ROW EXECUTE PROCEDURE atualiza_estoque_func();

-- ########################################################################################################

INSERT INTO regiao_geografica (nome) VALUES ('Norte'), ('Nordeste'), ('Centro-Oeste'), ('Sudeste'), ('Sul');

INSERT INTO estado (id, nome, uf, regiao_id, area_km2, populacao) VALUES
     (1, 'Acre',                'AC', 1,  164123,   829780),
     (2, 'Alagoas',             'AL', 2,   27848,  3125254),
     (3, 'Amazonas',            'AM', 1, 1559167,  3952262),
     (4, 'Amapá',               'AP', 1,  142470,   774268),
     (5, 'Bahia',               'BA', 2,  564760, 14659023),
     (6, 'Ceará',               'CE', 2,  148894,  8936431),
     (7, 'Distrito Federal',    'DF', 3,    5760,  2923369),
     (8, 'Espírito Santo',      'ES', 4,   46074,  4108508),
     (9, 'Goiás',               'GO', 3,  340203,  6950976),
     (10, 'Maranhão',           'MA', 2,  329642,  6800605),
     (11, 'Minas Gerais',       'MG', 4,  586521, 20732660),
     (12, 'Mato Grosso do Sul', 'MS', 3,  357145,  2833742),
     (13, 'Mato Grosso',        'MT', 3,  903207,  3784239),
     (14, 'Pará',               'PA', 1, 1245870,  8442962),
     (15, 'Paraíba',            'PB', 2,   56467,  4030961),
     (16, 'Pernambuco',         'PE', 2,   98067,  9051113),
     (17, 'Piauí',              'PI', 2,  251756,  3270174),
     (18, 'Paraná',             'PR', 5,  199298, 11835379),
     (19, 'Rio de Janeiro',     'RJ', 4,   43750, 16615526),
     (20, 'Rio Grande do Norte','RN', 2,   52809,  3303953),
     (21, 'Rondônia',           'RO', 1,  237765,  1616379),
     (22, 'Roraima',            'RR', 1,  223644,   634805),
     (23, 'Rio Grande do Sul',  'RS', 5,  281707, 11088065),
     (24, 'Santa Catarina',     'SC', 5,   95730,  7762154),
     (25, 'Sergipe',            'SE', 2,   21925,  2211868),
     (26, 'São Paulo',          'SP', 4,  248219, 46024937),
     (27, 'Tocantins',          'TO', 1,  277466,  1584306);


INSERT INTO cidade (id, nome, estado_id) VALUES
     (1, 'Afonso Cláudio', 8),
     (2, 'Água Doce do Norte', 8),
     (3, 'Águia Branca', 8),
     (4, 'Alegre', 8),
     (5, 'Alfredo Chaves', 8),
     (6, 'Alto Rio Novo', 8),
     (7, 'Anchieta', 8),
     (8, 'Apiacá', 8),
     (9, 'Aracruz', 8),
     (10, 'Atilio Vivacqua', 8),
     (11, 'Baixo Guandu', 8),
     (12, 'Barra de São Francisco', 8),
     (13, 'Boa Esperança', 8),
     (14, 'Bom Jesus do Norte', 8),
     (15, 'Brejetuba', 8),
     (16, 'Cachoeiro de Itapemirim', 8),
     (17, 'Cariacica', 8),
     (18, 'Castelo', 8),
     (19, 'Colatina', 8),
     (20, 'Conceição da Barra', 8),
     (21, 'Conceição do Castelo', 8),
     (22, 'Divino de São Lourenço', 8),
     (23, 'Domingos Martins', 8),
     (24, 'Dores do Rio Preto', 8),
     (25, 'Ecoporanga', 8),
     (26, 'Fundão', 8),
     (27, 'Governador Lindenberg', 8),
     (28, 'Guaçuí', 8),
     (29, 'Guarapari', 8),
     (30, 'Ibatiba', 8),
     (31, 'Ibiraçu', 8),
     (32, 'Ibitirama', 8),
     (33, 'Iconha', 8),
     (34, 'Irupi', 8),
     (35, 'Itaguaçu', 8),
     (36, 'Itapemirim', 8),
     (37, 'Itarana', 8),
     (38, 'Iúna', 8),
     (39, 'Jaguaré', 8),
     (40, 'Jerônimo Monteiro', 8),
     (41, 'João Neiva', 8),
     (42, 'Laranja da Terra', 8),
     (43, 'Linhares', 8),
     (44, 'Mantenópolis', 8),
     (45, 'Marataízes', 8),
     (46, 'Marechal Floriano', 8),
     (47, 'Marilândia', 8),
     (48, 'Mimoso do Sul', 8),
     (49, 'Montanha', 8),
     (50, 'Mucurici', 8),
     (51, 'Muniz Freire', 8),
     (52, 'Muqui', 8),
     (53, 'Nova Venécia', 8),
     (54, 'Pancas', 8),
     (55, 'Pedro Canário', 8),
     (56, 'Pinheiros', 8),
     (57, 'Piúma', 8),
     (58, 'Ponto Belo', 8),
     (59, 'Presidente Kennedy', 8),
     (60, 'Rio Bananal', 8),
     (61, 'Rio Novo do Sul', 8),
     (62, 'Santa Leopoldina', 8),
     (63, 'Santa Maria de Jetibá', 8),
     (64, 'Santa Teresa', 8),
     (65, 'São Domingos do Norte', 8),
     (66, 'São Gabriel da Palha', 8),
     (67, 'São José do Calçado', 8),
     (68, 'São Mateus', 8),
     (69, 'São Roque do Canaã', 8),
     (70, 'Serra', 8),
     (71, 'Sooretama', 8),
     (72, 'Vargem Alta', 8),
     (73, 'Venda Nova do Imigrante', 8),
     (74, 'Viana', 8),
     (75, 'Vila Pavão', 8),
     (76, 'Vila Valério', 8),
     (77, 'Vila Velha', 8),
     (78, 'Vitória', 8),
     (79, 'Acrelândia', 1),
     (80, 'Assis Brasil', 1),
     (81, 'Brasiléia', 1),
     (82, 'Bujari', 1),
     (83, 'Capixaba', 1),
     (84, 'Cruzeiro do Sul', 1),
     (85, 'Epitaciolândia', 1),
     (86, 'Feijó', 1),
     (87, 'Jordão', 1),
     (88, 'Mâncio Lima', 1),
     (89, 'Manoel Urbano', 1),
     (90, 'Marechal Thaumaturgo', 1),
     (91, 'Plácido de Castro', 1),
     (92, 'Porto Acre', 1),
     (93, 'Porto Walter', 1),
     (94, 'Rio Branco', 1),
     (95, 'Rodrigues Alves', 1),
     (96, 'Santa Rosa do Purus', 1),
     (97, 'Sena Madureira', 1),
     (98, 'Senador Guiomard', 1),
     (99, 'Tarauacá', 1),
     (100, 'Xapuri', 1),
     (101, 'Água Branca', 2),
     (102, 'Anadia', 2),
     (103, 'Arapiraca', 2),
     (104, 'Atalaia', 2),
     (105, 'Barra de Santo Antônio', 2),
     (106, 'Barra de São Miguel', 2),
     (107, 'Batalha', 2),
     (108, 'Belém', 2),
     (109, 'Belo Monte', 2),
     (110, 'Boca da Mata', 2),
     (111, 'Branquinha', 2),
     (112, 'Cacimbinhas', 2),
     (113, 'Cajueiro', 2),
     (114, 'Campestre', 2),
     (115, 'Campo Alegre', 2),
     (116, 'Campo Grande', 2),
     (117, 'Canapi', 2),
     (118, 'Capela', 2),
     (119, 'Carneiros', 2),
     (120, 'Chã Preta', 2),
     (121, 'Coité do Nóia', 2),
     (122, 'Colônia Leopoldina', 2),
     (123, 'Coqueiro Seco', 2),
     (124, 'Coruripe', 2),
     (125, 'Craíbas', 2),
     (126, 'Delmiro Gouveia', 2),
     (127, 'Dois Riachos', 2),
     (128, 'Estrela de Alagoas', 2),
     (129, 'Feira Grande', 2),
     (130, 'Feliz Deserto', 2),
     (131, 'Flexeiras', 2),
     (132, 'Girau do Ponciano', 2),
     (133, 'Ibateguara', 2),
     (134, 'Igaci', 2),
     (135, 'Igreja Nova', 2),
     (136, 'Inhapi', 2),
     (137, 'Jacaré dos Homens', 2),
     (138, 'Jacuípe', 2),
     (139, 'Japaratinga', 2),
     (140, 'Jaramataia', 2),
     (141, 'Jequiá da Praia', 2),
     (142, 'Joaquim Gomes', 2),
     (143, 'Jundiá', 2),
     (144, 'Junqueiro', 2),
     (145, 'Lagoa da Canoa', 2),
     (146, 'Limoeiro de Anadia', 2),
     (147, 'Maceió', 2),
     (148, 'Major Isidoro', 2),
     (149, 'Mar Vermelho', 2),
     (150, 'Maragogi', 2),
     (151, 'Maravilha', 2),
     (152, 'Marechal Deodoro', 2),
     (153, 'Maribondo', 2),
     (154, 'Mata Grande', 2),
     (155, 'Matriz de Camaragibe', 2),
     (156, 'Messias', 2),
     (157, 'Minador do Negrão', 2),
     (158, 'Monteirópolis', 2),
     (159, 'Murici', 2),
     (160, 'Novo Lino', 2),
     (161, 'Olho dÁgua das Flores', 2),
     (162, 'Olho dÁgua do Casado', 2),
     (163, 'Olho dÁgua Grande', 2),
     (164, 'Olivença', 2),
     (165, 'Ouro Branco', 2),
     (166, 'Palestina', 2),
     (167, 'Palmeira dos Índios', 2),
     (168, 'Pão de Açúcar', 2),
     (169, 'Pariconha', 2),
     (170, 'Paripueira', 2),
     (171, 'Passo de Camaragibe', 2),
     (172, 'Paulo Jacinto', 2),
     (173, 'Penedo', 2),
     (174, 'Piaçabuçu', 2),
     (175, 'Pilar', 2),
     (176, 'Pindoba', 2),
     (177, 'Piranhas', 2),
     (178, 'Poço das Trincheiras', 2),
     (179, 'Porto Calvo', 2),
     (180, 'Porto de Pedras', 2),
     (181, 'Porto Real do Colégio', 2),
     (182, 'Quebrangulo', 2),
     (183, 'Rio Largo', 2),
     (184, 'Roteiro', 2),
     (185, 'Santa Luzia do Norte', 2),
     (186, 'Santana do Ipanema', 2),
     (187, 'Santana do Mundaú', 2),
     (188, 'São Brás', 2),
     (189, 'São José da Laje', 2),
     (190, 'São José da Tapera', 2),
     (191, 'São Luís do Quitunde', 2),
     (192, 'São Miguel dos Campos', 2),
     (193, 'São Miguel dos Milagres', 2),
     (194, 'São Sebastião', 2),
     (195, 'Satuba', 2),
     (196, 'Senador Rui Palmeira', 2),
     (197, 'Tanque dArca', 2),
     (198, 'Taquarana', 2),
     (199, 'Teotônio Vilela', 2),
     (200, 'Traipu', 2),
     (201, 'União dos Palmares', 2),
     (202, 'Viçosa', 2),
     (203, 'Amapá', 4),
     (204, 'Calçoene', 4),
     (205, 'Cutias', 4),
     (206, 'Ferreira Gomes', 4),
     (207, 'Itaubal', 4),
     (208, 'Laranjal do Jari', 4),
     (209, 'Macapá', 4),
     (210, 'Mazagão', 4),
     (211, 'Oiapoque', 4),
     (212, 'Pedra Branca do Amaparí', 4),
     (213, 'Porto Grande', 4),
     (214, 'Pracuúba', 4),
     (215, 'Santana', 4),
     (216, 'Serra do Navio', 4),
     (217, 'Tartarugalzinho', 4),
     (218, 'Vitória do Jari', 4),
     (219, 'Alvarães', 3),
     (220, 'Amaturá', 3),
     (221, 'Anamã', 3),
     (222, 'Anori', 3),
     (223, 'Apuí', 3),
     (224, 'Atalaia do Norte', 3),
     (225, 'Autazes', 3),
     (226, 'Barcelos', 3),
     (227, 'Barreirinha', 3),
     (228, 'Benjamin Constant', 3),
     (229, 'Beruri', 3),
     (230, 'Boa Vista do Ramos', 3),
     (231, 'Boca do Acre', 3),
     (232, 'Borba', 3),
     (233, 'Caapiranga', 3),
     (234, 'Canutama', 3),
     (235, 'Carauari', 3),
     (236, 'Careiro', 3),
     (237, 'Careiro da Várzea', 3),
     (238, 'Coari', 3),
     (239, 'Codajás', 3),
     (240, 'Eirunepé', 3),
     (241, 'Envira', 3),
     (242, 'Fonte Boa', 3),
     (243, 'Guajará', 3),
     (244, 'Humaitá', 3),
     (245, 'Ipixuna', 3),
     (246, 'Iranduba', 3),
     (247, 'Itacoatiara', 3),
     (248, 'Itamarati', 3),
     (249, 'Itapiranga', 3),
     (250, 'Japurá', 3),
     (251, 'Juruá', 3),
     (252, 'Jutaí', 3),
     (253, 'Lábrea', 3),
     (254, 'Manacapuru', 3),
     (255, 'Manaquiri', 3),
     (256, 'Manaus', 3),
     (257, 'Manicoré', 3),
     (258, 'Maraã', 3),
     (259, 'Maués', 3),
     (260, 'Nhamundá', 3),
     (261, 'Nova Olinda do Norte', 3),
     (262, 'Novo Airão', 3),
     (263, 'Novo Aripuanã', 3),
     (264, 'Parintins', 3),
     (265, 'Pauini', 3),
     (266, 'Presidente Figueiredo', 3),
     (267, 'Rio Preto da Eva', 3),
     (268, 'Santa Isabel do Rio Negro', 3),
     (269, 'Santo Antônio do Içá', 3),
     (270, 'São Gabriel da Cachoeira', 3),
     (271, 'São Paulo de Olivença', 3),
     (272, 'São Sebastião do Uatumã', 3),
     (273, 'Silves', 3),
     (274, 'Tabatinga', 3),
     (275, 'Tapauá', 3),
     (276, 'Tefé', 3),
     (277, 'Tonantins', 3),
     (278, 'Uarini', 3),
     (279, 'Urucará', 3),
     (280, 'Urucurituba', 3),
     (281, 'Abaíra', 5),
     (282, 'Abaré', 5),
     (283, 'Acajutiba', 5),
     (284, 'Adustina', 5),
     (285, 'Água Fria', 5),
     (286, 'Aiquara', 5),
     (287, 'Alagoinhas', 5),
     (288, 'Alcobaça', 5),
     (289, 'Almadina', 5),
     (290, 'Amargosa', 5),
     (291, 'Amélia Rodrigues', 5),
     (292, 'América Dourada', 5),
     (293, 'Anagé', 5),
     (294, 'Andaraí', 5),
     (295, 'Andorinha', 5),
     (296, 'Angical', 5),
     (297, 'Anguera', 5),
     (298, 'Antas', 5),
     (299, 'Antônio Cardoso', 5),
     (300, 'Antônio Gonçalves', 5),
     (301, 'Aporá', 5),
     (302, 'Apuarema', 5),
     (303, 'Araças', 5),
     (304, 'Aracatu', 5),
     (305, 'Araci', 5),
     (306, 'Aramari', 5),
     (307, 'Arataca', 5),
     (308, 'Aratuípe', 5),
     (309, 'Aurelino Leal', 5),
     (310, 'Baianópolis', 5),
     (311, 'Baixa Grande', 5),
     (312, 'Banzaê', 5),
     (313, 'Barra', 5),
     (314, 'Barra da Estiva', 5),
     (315, 'Barra do Choça', 5),
     (316, 'Barra do Mendes', 5),
     (317, 'Barra do Rocha', 5),
     (318, 'Barreiras', 5),
     (319, 'Barro Alto', 5),
     (320, 'Barro Preto (antigo Gov. Lomanto Jr.)', 5),
     (321, 'Barrocas', 5),
     (322, 'Belmonte', 5),
     (323, 'Belo Campo', 5),
     (324, 'Biritinga', 5),
     (325, 'Boa Nova', 5),
     (326, 'Boa Vista do Tupim', 5),
     (327, 'Bom Jesus da Lapa', 5),
     (328, 'Bom Jesus da Serra', 5),
     (329, 'Boninal', 5),
     (330, 'Bonito', 5),
     (331, 'Boquira', 5),
     (332, 'Botuporã', 5),
     (333, 'Brejões', 5),
     (334, 'Brejolândia', 5),
     (335, 'Brotas de Macaúbas', 5),
     (336, 'Brumado', 5),
     (337, 'Buerarema', 5),
     (338, 'Buritirama', 5),
     (339, 'Caatiba', 5),
     (340, 'Cabaceiras do Paraguaçu', 5),
     (341, 'Cachoeira', 5),
     (342, 'Caculé', 5),
     (343, 'Caém', 5),
     (344, 'Caetanos', 5),
     (345, 'Caetité', 5),
     (346, 'Cafarnaum', 5),
     (347, 'Cairu', 5),
     (348, 'Caldeirão Grande', 5),
     (349, 'Camacan', 5),
     (350, 'Camaçari', 5),
     (351, 'Camamu', 5),
     (352, 'Campo Alegre de Lourdes', 5),
     (353, 'Campo Formoso', 5),
     (354, 'Canápolis', 5),
     (355, 'Canarana', 5),
     (356, 'Canavieiras', 5),
     (357, 'Candeal', 5),
     (358, 'Candeias', 5),
     (359, 'Candiba', 5),
     (360, 'Cândido Sales', 5),
     (361, 'Cansanção', 5),
     (362, 'Canudos', 5),
     (363, 'Capela do Alto Alegre', 5),
     (364, 'Capim Grosso', 5),
     (365, 'Caraíbas', 5),
     (366, 'Caravelas', 5),
     (367, 'Cardeal da Silva', 5),
     (368, 'Carinhanha', 5),
     (369, 'Casa Nova', 5),
     (370, 'Castro Alves', 5),
     (371, 'Catolândia', 5),
     (372, 'Catu', 5),
     (373, 'Caturama', 5),
     (374, 'Central', 5),
     (375, 'Chorrochó', 5),
     (376, 'Cícero Dantas', 5),
     (377, 'Cipó', 5),
     (378, 'Coaraci', 5),
     (379, 'Cocos', 5),
     (380, 'Conceição da Feira', 5),
     (381, 'Conceição do Almeida', 5),
     (382, 'Conceição do Coité', 5),
     (383, 'Conceição do Jacuípe', 5),
     (384, 'Conde', 5),
     (385, 'Condeúba', 5),
     (386, 'Contendas do Sincorá', 5),
     (387, 'Coração de Maria', 5),
     (388, 'Cordeiros', 5),
     (389, 'Coribe', 5),
     (390, 'Coronel João Sá', 5),
     (391, 'Correntina', 5),
     (392, 'Cotegipe', 5),
     (393, 'Cravolândia', 5),
     (394, 'Crisópolis', 5),
     (395, 'Cristópolis', 5),
     (396, 'Cruz das Almas', 5),
     (397, 'Curaçá', 5),
     (398, 'Dário Meira', 5),
     (399, 'Dias dÁvila', 5),
     (400, 'Dom Basílio', 5),
     (401, 'Dom Macedo Costa', 5),
     (402, 'Elísio Medrado', 5),
     (403, 'Encruzilhada', 5),
     (404, 'Entre Rios', 5),
     (405, 'Érico Cardoso', 5),
     (406, 'Esplanada', 5),
     (407, 'Euclides da Cunha', 5),
     (408, 'Eunápolis', 5),
     (409, 'Fátima', 5),
     (410, 'Feira da Mata', 5),
     (411, 'Feira de Santana', 5),
     (412, 'Filadélfia', 5),
     (413, 'Firmino Alves', 5),
     (414, 'Floresta Azul', 5),
     (415, 'Formosa do Rio Preto', 5),
     (416, 'Gandu', 5),
     (417, 'Gavião', 5),
     (418, 'Gentio do Ouro', 5),
     (419, 'Glória', 5),
     (420, 'Gongogi', 5),
     (421, 'Governador Mangabeira', 5),
     (422, 'Guajeru', 5),
     (423, 'Guanambi', 5),
     (424, 'Guaratinga', 5),
     (425, 'Heliópolis', 5),
     (426, 'Iaçu', 5),
     (427, 'Ibiassucê', 5),
     (428, 'Ibicaraí', 5),
     (429, 'Ibicoara', 5),
     (430, 'Ibicuí', 5),
     (431, 'Ibipeba', 5),
     (432, 'Ibipitanga', 5),
     (433, 'Ibiquera', 5),
     (434, 'Ibirapitanga', 5),
     (435, 'Ibirapuã', 5),
     (436, 'Ibirataia', 5),
     (437, 'Ibitiara', 5),
     (438, 'Ibititá', 5),
     (439, 'Ibotirama', 5),
     (440, 'Ichu', 5),
     (441, 'Igaporã', 5),
     (442, 'Igrapiúna', 5),
     (443, 'Iguaí', 5),
     (444, 'Ilhéus', 5),
     (445, 'Inhambupe', 5),
     (446, 'Ipecaetá', 5),
     (447, 'Ipiaú', 5),
     (448, 'Ipirá', 5),
     (449, 'Ipupiara', 5),
     (450, 'Irajuba', 5),
     (451, 'Iramaia', 5),
     (452, 'Iraquara', 5),
     (453, 'Irará', 5),
     (454, 'Irecê', 5),
     (455, 'Itabela', 5),
     (456, 'Itaberaba', 5),
     (457, 'Itabuna', 5),
     (458, 'Itacaré', 5),
     (459, 'Itaeté', 5),
     (460, 'Itagi', 5),
     (461, 'Itagibá', 5),
     (462, 'Itagimirim', 5),
     (463, 'Itaguaçu da Bahia', 5),
     (464, 'Itaju do Colônia', 5),
     (465, 'Itajuípe', 5),
     (466, 'Itamaraju', 5),
     (467, 'Itamari', 5),
     (468, 'Itambé', 5),
     (469, 'Itanagra', 5),
     (470, 'Itanhém', 5),
     (471, 'Itaparica', 5),
     (472, 'Itapé', 5),
     (473, 'Itapebi', 5),
     (474, 'Itapetinga', 5),
     (475, 'Itapicuru', 5),
     (476, 'Itapitanga', 5),
     (477, 'Itaquara', 5),
     (478, 'Itarantim', 5),
     (479, 'Itatim', 5),
     (480, 'Itiruçu', 5),
     (481, 'Itiúba', 5),
     (482, 'Itororó', 5),
     (483, 'Ituaçu', 5),
     (484, 'Ituberá', 5),
     (485, 'Iuiú', 5),
     (486, 'Jaborandi', 5),
     (487, 'Jacaraci', 5),
     (488, 'Jacobina', 5),
     (489, 'Jaguaquara', 5),
     (490, 'Jaguarari', 5),
     (491, 'Jaguaripe', 5),
     (492, 'Jandaíra', 5),
     (493, 'Jequié', 5),
     (494, 'Jeremoabo', 5),
     (495, 'Jiquiriçá', 5),
     (496, 'Jitaúna', 5),
     (497, 'João Dourado', 5),
     (498, 'Juazeiro', 5),
     (499, 'Jucuruçu', 5),
     (500, 'Jussara', 5),
     (501, 'Jussari', 5),
     (502, 'Jussiape', 5),
     (503, 'Lafaiete Coutinho', 5),
     (504, 'Lagoa Real', 5),
     (505, 'Laje', 5),
     (506, 'Lajedão', 5),
     (507, 'Lajedinho', 5),
     (508, 'Lajedo do Tabocal', 5),
     (509, 'Lamarão', 5),
     (510, 'Lapão', 5),
     (511, 'Lauro de Freitas', 5),
     (512, 'Lençóis', 5),
     (513, 'Licínio de Almeida', 5),
     (514, 'Livramento de Nossa Senhora', 5),
     (515, 'Luís Eduardo Magalhães', 5),
     (516, 'Macajuba', 5),
     (517, 'Macarani', 5),
     (518, 'Macaúbas', 5),
     (519, 'Macururé', 5),
     (520, 'Madre de Deus', 5),
     (521, 'Maetinga', 5),
     (522, 'Maiquinique', 5),
     (523, 'Mairi', 5),
     (524, 'Malhada', 5),
     (525, 'Malhada de Pedras', 5),
     (526, 'Manoel Vitorino', 5),
     (527, 'Mansidão', 5),
     (528, 'Maracás', 5),
     (529, 'Maragogipe', 5),
     (530, 'Maraú', 5),
     (531, 'Marcionílio Souza', 5),
     (532, 'Mascote', 5),
     (533, 'Mata de São João', 5),
     (534, 'Matina', 5),
     (535, 'Medeiros Neto', 5),
     (536, 'Miguel Calmon', 5),
     (537, 'Milagres', 5),
     (538, 'Mirangaba', 5),
     (539, 'Mirante', 5),
     (540, 'Monte Santo', 5),
     (541, 'Morpará', 5),
     (542, 'Morro do Chapéu', 5),
     (543, 'Mortugaba', 5),
     (544, 'Mucugê', 5),
     (545, 'Mucuri', 5),
     (546, 'Mulungu do Morro', 5),
     (547, 'Mundo Novo', 5),
     (548, 'Muniz Ferreira', 5),
     (549, 'Muquém de São Francisco', 5),
     (550, 'Muritiba', 5),
     (551, 'Mutuípe', 5),
     (552, 'Nazaré', 5),
     (553, 'Nilo Peçanha', 5),
     (554, 'Nordestina', 5),
     (555, 'Nova Canaã', 5),
     (556, 'Nova Fátima', 5),
     (557, 'Nova Ibiá', 5),
     (558, 'Nova Itarana', 5),
     (559, 'Nova Redenção', 5),
     (560, 'Nova Soure', 5),
     (561, 'Nova Viçosa', 5),
     (562, 'Novo Horizonte', 5),
     (563, 'Novo Triunfo', 5),
     (564, 'Olindina', 5),
     (565, 'Oliveira dos Brejinhos', 5),
     (566, 'Ouriçangas', 5),
     (567, 'Ourolândia', 5),
     (568, 'Palmas de Monte Alto', 5),
     (569, 'Palmeiras', 5),
     (570, 'Paramirim', 5),
     (571, 'Paratinga', 5),
     (572, 'Paripiranga', 5),
     (573, 'Pau Brasil', 5),
     (574, 'Paulo Afonso', 5),
     (575, 'Pé de Serra', 5),
     (576, 'Pedrão', 5),
     (577, 'Pedro Alexandre', 5),
     (578, 'Piatã', 5),
     (579, 'Pilão Arcado', 5),
     (580, 'Pindaí', 5),
     (581, 'Pindobaçu', 5),
     (582, 'Pintadas', 5),
     (583, 'Piraí do Norte', 5),
     (584, 'Piripá', 5),
     (585, 'Piritiba', 5),
     (586, 'Planaltino', 5),
     (587, 'Planalto', 5),
     (588, 'Poções', 5),
     (589, 'Pojuca', 5),
     (590, 'Ponto Novo', 5),
     (591, 'Porto Seguro', 5),
     (592, 'Potiraguá', 5),
     (593, 'Prado', 5),
     (594, 'Presidente Dutra', 5),
     (595, 'Presidente Jânio Quadros', 5),
     (596, 'Presidente Tancredo Neves', 5),
     (597, 'Queimadas', 5),
     (598, 'Quijingue', 5),
     (599, 'Quixabeira', 5),
     (600, 'Rafael Jambeiro', 5),
     (601, 'Remanso', 5),
     (602, 'Retirolândia', 5),
     (603, 'Riachão das Neves', 5),
     (604, 'Riachão do Jacuípe', 5),
     (605, 'Riacho de Santana', 5),
     (606, 'Ribeira do Amparo', 5),
     (607, 'Ribeira do Pombal', 5),
     (608, 'Ribeirão do Largo', 5),
     (609, 'Rio de Contas', 5),
     (610, 'Rio do Antônio', 5),
     (611, 'Rio do Pires', 5),
     (612, 'Rio Real', 5),
     (613, 'Rodelas', 5),
     (614, 'Ruy Barbosa', 5),
     (615, 'Salinas da Margarida', 5),
     (616, 'Salvador', 5),
     (617, 'Santa Bárbara', 5),
     (618, 'Santa Brígida', 5),
     (619, 'Santa Cruz Cabrália', 5),
     (620, 'Santa Cruz da Vitória', 5),
     (621, 'Santa Inês', 5),
     (622, 'Santa Luzia', 5),
     (623, 'Santa Maria da Vitória', 5),
     (624, 'Santa Rita de Cássia', 5),
     (625, 'Santa Teresinha', 5),
     (626, 'Santaluz', 5),
     (627, 'Santana', 5),
     (628, 'Santanópolis', 5),
     (629, 'Santo Amaro', 5),
     (630, 'Santo Antônio de Jesus', 5),
     (631, 'Santo Estêvão', 5),
     (632, 'São Desidério', 5),
     (633, 'São Domingos', 5),
     (634, 'São Felipe', 5),
     (635, 'São Félix', 5),
     (636, 'São Félix do Coribe', 5),
     (637, 'São Francisco do Conde', 5),
     (638, 'São Gabriel', 5),
     (639, 'São Gonçalo dos Campos', 5),
     (640, 'São José da Vitória', 5),
     (641, 'São José do Jacuípe', 5),
     (642, 'São Miguel das Matas', 5),
     (643, 'São Sebastião do Passé', 5),
     (644, 'Sapeaçu', 5),
     (645, 'Sátiro Dias', 5),
     (646, 'Saubara', 5),
     (647, 'Saúde', 5),
     (648, 'Seabra', 5),
     (649, 'Sebastião Laranjeiras', 5),
     (650, 'Senhor do Bonfim', 5),
     (651, 'Sento Sé', 5),
     (652, 'Serra do Ramalho', 5),
     (653, 'Serra Dourada', 5),
     (654, 'Serra Preta', 5),
     (655, 'Serrinha', 5),
     (656, 'Serrolândia', 5),
     (657, 'Simões Filho', 5),
     (658, 'Sítio do Mato', 5),
     (659, 'Sítio do Quinto', 5),
     (660, 'Sobradinho', 5),
     (661, 'Souto Soares', 5),
     (662, 'Tabocas do Brejo Velho', 5),
     (663, 'Tanhaçu', 5),
     (664, 'Tanque Novo', 5),
     (665, 'Tanquinho', 5),
     (666, 'Taperoá', 5),
     (667, 'Tapiramutá', 5),
     (668, 'Teixeira de Freitas', 5),
     (669, 'Teodoro Sampaio', 5),
     (670, 'Teofilândia', 5),
     (671, 'Teolândia', 5),
     (672, 'Terra Nova', 5),
     (673, 'Tremedal', 5),
     (674, 'Tucano', 5),
     (675, 'Uauá', 5),
     (676, 'Ubaíra', 5),
     (677, 'Ubaitaba', 5),
     (678, 'Ubatã', 5),
     (679, 'Uibaí', 5),
     (680, 'Umburanas', 5),
     (681, 'Una', 5),
     (682, 'Urandi', 5),
     (683, 'Uruçuca', 5),
     (684, 'Utinga', 5),
     (685, 'Valença', 5),
     (686, 'Valente', 5),
     (687, 'Várzea da Roça', 5),
     (688, 'Várzea do Poço', 5),
     (689, 'Várzea Nova', 5),
     (690, 'Varzedo', 5),
     (691, 'Vera Cruz', 5),
     (692, 'Vereda', 5),
     (693, 'Vitória da Conquista', 5),
     (694, 'Wagner', 5),
     (695, 'Wanderley', 5),
     (696, 'Wenceslau Guimarães', 5),
     (697, 'Xique-Xique', 5),
     (698, 'Abaiara', 6),
     (699, 'Acarape', 6),
     (700, 'Acaraú', 6),
     (701, 'Acopiara', 6),
     (702, 'Aiuaba', 6),
     (703, 'Alcântaras', 6),
     (704, 'Altaneira', 6),
     (705, 'Alto Santo', 6),
     (706, 'Amontada', 6),
     (707, 'Antonina do Norte', 6),
     (708, 'Apuiarés', 6),
     (709, 'Aquiraz', 6),
     (710, 'Aracati', 6),
     (711, 'Aracoiaba', 6),
     (712, 'Ararendá', 6),
     (713, 'Araripe', 6),
     (714, 'Aratuba', 6),
     (715, 'Arneiroz', 6),
     (716, 'Assaré', 6),
     (717, 'Aurora', 6),
     (718, 'Baixio', 6),
     (719, 'Banabuiú', 6),
     (720, 'Barbalha', 6),
     (721, 'Barreira', 6),
     (722, 'Barro', 6),
     (723, 'Barroquinha', 6),
     (724, 'Baturité', 6),
     (725, 'Beberibe', 6),
     (726, 'Bela Cruz', 6),
     (727, 'Boa Viagem', 6),
     (728, 'Brejo Santo', 6),
     (729, 'Camocim', 6),
     (730, 'Campos Sales', 6),
     (731, 'Canindé', 6),
     (732, 'Capistrano', 6),
     (733, 'Caridade', 6),
     (734, 'Cariré', 6),
     (735, 'Caririaçu', 6),
     (736, 'Cariús', 6),
     (737, 'Carnaubal', 6),
     (738, 'Cascavel', 6),
     (739, 'Catarina', 6),
     (740, 'Catunda', 6),
     (741, 'Caucaia', 6),
     (742, 'Cedro', 6),
     (743, 'Chaval', 6),
     (744, 'Choró', 6),
     (745, 'Chorozinho', 6),
     (746, 'Coreaú', 6),
     (747, 'Crateús', 6),
     (748, 'Crato', 6),
     (749, 'Croatá', 6),
     (750, 'Cruz', 6),
     (751, 'Deputado Irapuan Pinheiro', 6),
     (752, 'Ererê', 6),
     (753, 'Eusébio', 6),
     (754, 'Farias Brito', 6),
     (755, 'Forquilha', 6),
     (756, 'Fortaleza', 6),
     (757, 'Fortim', 6),
     (758, 'Frecheirinha', 6),
     (759, 'General Sampaio', 6),
     (760, 'Graça', 6),
     (761, 'Granja', 6),
     (762, 'Granjeiro', 6),
     (763, 'Groaíras', 6),
     (764, 'Guaiúba', 6),
     (765, 'Guaraciaba do Norte', 6),
     (766, 'Guaramiranga', 6),
     (767, 'Hidrolândia', 6),
     (768, 'Horizonte', 6),
     (769, 'Ibaretama', 6),
     (770, 'Ibiapina', 6),
     (771, 'Ibicuitinga', 6),
     (772, 'Icapuí', 6),
     (773, 'Icó', 6),
     (774, 'Iguatu', 6),
     (775, 'Independência', 6),
     (776, 'Ipaporanga', 6),
     (777, 'Ipaumirim', 6),
     (778, 'Ipu', 6),
     (779, 'Ipueiras', 6),
     (780, 'Iracema', 6),
     (781, 'Irauçuba', 6),
     (782, 'Itaiçaba', 6),
     (783, 'Itaitinga', 6),
     (784, 'Itapagé', 6),
     (785, 'Itapipoca', 6),
     (786, 'Itapiúna', 6),
     (787, 'Itarema', 6),
     (788, 'Itatira', 6),
     (789, 'Jaguaretama', 6),
     (790, 'Jaguaribara', 6),
     (791, 'Jaguaribe', 6),
     (792, 'Jaguaruana', 6),
     (793, 'Jardim', 6),
     (794, 'Jati', 6),
     (795, 'Jijoca de Jericoacoara', 6),
     (796, 'Juazeiro do Norte', 6),
     (797, 'Jucás', 6),
     (798, 'Lavras da Mangabeira', 6),
     (799, 'Limoeiro do Norte', 6),
     (800, 'Madalena', 6),
     (801, 'Maracanaú', 6),
     (802, 'Maranguape', 6),
     (803, 'Marco', 6),
     (804, 'Martinópole', 6),
     (805, 'Massapê', 6),
     (806, 'Mauriti', 6),
     (807, 'Meruoca', 6),
     (808, 'Milagres', 6),
     (809, 'Milhã', 6),
     (810, 'Miraíma', 6),
     (811, 'Missão Velha', 6),
     (812, 'Mombaça', 6),
     (813, 'Monsenhor Tabosa', 6),
     (814, 'Morada Nova', 6),
     (815, 'Moraújo', 6),
     (816, 'Morrinhos', 6),
     (817, 'Mucambo', 6),
     (818, 'Mulungu', 6),
     (819, 'Nova Olinda', 6),
     (820, 'Nova Russas', 6),
     (821, 'Novo Oriente', 6),
     (822, 'Ocara', 6),
     (823, 'Orós', 6),
     (824, 'Pacajus', 6),
     (825, 'Pacatuba', 6),
     (826, 'Pacoti', 6),
     (827, 'Pacujá', 6),
     (828, 'Palhano', 6),
     (829, 'Palmácia', 6),
     (830, 'Paracuru', 6),
     (831, 'Paraipaba', 6),
     (832, 'Parambu', 6),
     (833, 'Paramoti', 6),
     (834, 'Pedra Branca', 6),
     (835, 'Penaforte', 6),
     (836, 'Pentecoste', 6),
     (837, 'Pereiro', 6),
     (838, 'Pindoretama', 6),
     (839, 'Piquet Carneiro', 6),
     (840, 'Pires Ferreira', 6),
     (841, 'Poranga', 6),
     (842, 'Porteiras', 6),
     (843, 'Potengi', 6),
     (844, 'Potiretama', 6),
     (845, 'Quiterianópolis', 6),
     (846, 'Quixadá', 6),
     (847, 'Quixelô', 6),
     (848, 'Quixeramobim', 6),
     (849, 'Quixeré', 6),
     (850, 'Redenção', 6),
     (851, 'Reriutaba', 6),
     (852, 'Russas', 6),
     (853, 'Saboeiro', 6),
     (854, 'Salitre', 6),
     (855, 'Santa Quitéria', 6),
     (856, 'Santana do Acaraú', 6),
     (857, 'Santana do Cariri', 6),
     (858, 'São Benedito', 6),
     (859, 'São Gonçalo do Amarante', 6),
     (860, 'São João do Jaguaribe', 6),
     (861, 'São Luís do Curu', 6),
     (862, 'Senador Pompeu', 6),
     (863, 'Senador Sá', 6),
     (864, 'Sobral', 6),
     (865, 'Solonópole', 6),
     (866, 'Tabuleiro do Norte', 6),
     (867, 'Tamboril', 6),
     (868, 'Tarrafas', 6),
     (869, 'Tauá', 6),
     (870, 'Tejuçuoca', 6),
     (871, 'Tianguá', 6),
     (872, 'Trairi', 6),
     (873, 'Tururu', 6),
     (874, 'Ubajara', 6),
     (875, 'Umari', 6),
     (876, 'Umirim', 6),
     (877, 'Uruburetama', 6),
     (878, 'Uruoca', 6),
     (879, 'Varjota', 6),
     (880, 'Várzea Alegre', 6),
     (881, 'Viçosa do Ceará', 6),
     (882, 'Brasília', 7),
     (883, 'Abadia de Goiás', 9),
     (884, 'Abadiânia', 9),
     (885, 'Acreúna', 9),
     (886, 'Adelândia', 9),
     (887, 'Água Fria de Goiás', 9),
     (888, 'Água Limpa', 9),
     (889, 'Águas Lindas de Goiás', 9),
     (890, 'Alexânia', 9),
     (891, 'Aloândia', 9),
     (892, 'Alto Horizonte', 9),
     (893, 'Alto Paraíso de Goiás', 9),
     (894, 'Alvorada do Norte', 9),
     (895, 'Amaralina', 9),
     (896, 'Americano do Brasil', 9),
     (897, 'Amorinópolis', 9),
     (898, 'Anápolis', 9),
     (899, 'Anhanguera', 9),
     (900, 'Anicuns', 9),
     (901, 'Aparecida de Goiânia', 9),
     (902, 'Aparecida do Rio Doce', 9),
     (903, 'Aporé', 9),
     (904, 'Araçu', 9),
     (905, 'Aragarças', 9),
     (906, 'Aragoiânia', 9),
     (907, 'Araguapaz', 9),
     (908, 'Arenópolis', 9),
     (909, 'Aruanã', 9),
     (910, 'Aurilândia', 9),
     (911, 'Avelinópolis', 9),
     (912, 'Baliza', 9),
     (913, 'Barro Alto', 9),
     (914, 'Bela Vista de Goiás', 9),
     (915, 'Bom Jardim de Goiás', 9),
     (916, 'Bom Jesus de Goiás', 9),
     (917, 'Bonfinópolis', 9),
     (918, 'Bonópolis', 9),
     (919, 'Brazabrantes', 9),
     (920, 'Britânia', 9),
     (921, 'Buriti Alegre', 9),
     (922, 'Buriti de Goiás', 9),
     (923, 'Buritinópolis', 9),
     (924, 'Cabeceiras', 9),
     (925, 'Cachoeira Alta', 9),
     (926, 'Cachoeira de Goiás', 9),
     (927, 'Cachoeira Dourada', 9),
     (928, 'Caçu', 9),
     (929, 'Caiapônia', 9),
     (930, 'Caldas Novas', 9),
     (931, 'Caldazinha', 9),
     (932, 'Campestre de Goiás', 9),
     (933, 'Campinaçu', 9),
     (934, 'Campinorte', 9),
     (935, 'Campo Alegre de Goiás', 9),
     (936, 'Campo Limpo de Goiás', 9),
     (937, 'Campos Belos', 9),
     (938, 'Campos Verdes', 9),
     (939, 'Carmo do Rio Verde', 9),
     (940, 'Castelândia', 9),
     (941, 'Catalão', 9),
     (942, 'Caturaí', 9),
     (943, 'Cavalcante', 9),
     (944, 'Ceres', 9),
     (945, 'Cezarina', 9),
     (946, 'Chapadão do Céu', 9),
     (947, 'Cidade Ocidental', 9),
     (948, 'Cocalzinho de Goiás', 9),
     (949, 'Colinas do Sul', 9),
     (950, 'Córrego do Ouro', 9),
     (951, 'Corumbá de Goiás', 9),
     (952, 'Corumbaíba', 9),
     (953, 'Cristalina', 9),
     (954, 'Cristianópolis', 9),
     (955, 'Crixás', 9),
     (956, 'Cromínia', 9),
     (957, 'Cumari', 9),
     (958, 'Damianópolis', 9),
     (959, 'Damolândia', 9),
     (960, 'Davinópolis', 9),
     (961, 'Diorama', 9),
     (962, 'Divinópolis de Goiás', 9),
     (963, 'Doverlândia', 9),
     (964, 'Edealina', 9),
     (965, 'Edéia', 9),
     (966, 'Estrela do Norte', 9),
     (967, 'Faina', 9),
     (968, 'Fazenda Nova', 9),
     (969, 'Firminópolis', 9),
     (970, 'Flores de Goiás', 9),
     (971, 'Formosa', 9),
     (972, 'Formoso', 9),
     (973, 'Gameleira de Goiás', 9),
     (974, 'Goianápolis', 9),
     (975, 'Goiandira', 9),
     (976, 'Goianésia', 9),
     (977, 'Goiânia', 9),
     (978, 'Goianira', 9),
     (979, 'Goiás', 9),
     (980, 'Goiatuba', 9),
     (981, 'Gouvelândia', 9),
     (982, 'Guapó', 9),
     (983, 'Guaraíta', 9),
     (984, 'Guarani de Goiás', 9),
     (985, 'Guarinos', 9),
     (986, 'Heitoraí', 9),
     (987, 'Hidrolândia', 9),
     (988, 'Hidrolina', 9),
     (989, 'Iaciara', 9),
     (990, 'Inaciolândia', 9),
     (991, 'Indiara', 9),
     (992, 'Inhumas', 9),
     (993, 'Ipameri', 9),
     (994, 'Ipiranga de Goiás', 9),
     (995, 'Iporá', 9),
     (996, 'Israelândia', 9),
     (997, 'Itaberaí', 9),
     (998, 'Itaguari', 9),
     (999, 'Itaguaru', 9),
     (1000, 'Itajá', 9),
     (1001, 'Itapaci', 9),
     (1002, 'Itapirapuã', 9),
     (1003, 'Itapuranga', 9),
     (1004, 'Itarumã', 9),
     (1005, 'Itauçu', 9),
     (1006, 'Itumbiara', 9),
     (1007, 'Ivolândia', 9),
     (1008, 'Jandaia', 9),
     (1009, 'Jaraguá', 9),
     (1010, 'Jataí', 9),
     (1011, 'Jaupaci', 9),
     (1012, 'Jesúpolis', 9),
     (1013, 'Joviânia', 9),
     (1014, 'Jussara', 9),
     (1015, 'Lagoa Santa', 9),
     (1016, 'Leopoldo de Bulhões', 9),
     (1017, 'Luziânia', 9),
     (1018, 'Mairipotaba', 9),
     (1019, 'Mambaí', 9),
     (1020, 'Mara Rosa', 9),
     (1021, 'Marzagão', 9),
     (1022, 'Matrinchã', 9),
     (1023, 'Maurilândia', 9),
     (1024, 'Mimoso de Goiás', 9),
     (1025, 'Minaçu', 9),
     (1026, 'Mineiros', 9),
     (1027, 'Moiporá', 9),
     (1028, 'Monte Alegre de Goiás', 9),
     (1029, 'Montes Claros de Goiás', 9),
     (1030, 'Montividiu', 9),
     (1031, 'Montividiu do Norte', 9),
     (1032, 'Morrinhos', 9),
     (1033, 'Morro Agudo de Goiás', 9),
     (1034, 'Mossâmedes', 9),
     (1035, 'Mozarlândia', 9),
     (1036, 'Mundo Novo', 9),
     (1037, 'Mutunópolis', 9),
     (1038, 'Nazário', 9),
     (1039, 'Nerópolis', 9),
     (1040, 'Niquelândia', 9),
     (1041, 'Nova América', 9),
     (1042, 'Nova Aurora', 9),
     (1043, 'Nova Crixás', 9),
     (1044, 'Nova Glória', 9),
     (1045, 'Nova Iguaçu de Goiás', 9),
     (1046, 'Nova Roma', 9),
     (1047, 'Nova Veneza', 9),
     (1048, 'Novo Brasil', 9),
     (1049, 'Novo Gama', 9),
     (1050, 'Novo Planalto', 9),
     (1051, 'Orizona', 9),
     (1052, 'Ouro Verde de Goiás', 9),
     (1053, 'Ouvidor', 9),
     (1054, 'Padre Bernardo', 9),
     (1055, 'Palestina de Goiás', 9),
     (1056, 'Palmeiras de Goiás', 9),
     (1057, 'Palmelo', 9),
     (1058, 'Palminópolis', 9),
     (1059, 'Panamá', 9),
     (1060, 'Paranaiguara', 9),
     (1061, 'Paraúna', 9),
     (1062, 'Perolândia', 9),
     (1063, 'Petrolina de Goiás', 9),
     (1064, 'Pilar de Goiás', 9),
     (1065, 'Piracanjuba', 9),
     (1066, 'Piranhas', 9),
     (1067, 'Pirenópolis', 9),
     (1068, 'Pires do Rio', 9),
     (1069, 'Planaltina', 9),
     (1070, 'Pontalina', 9),
     (1071, 'Porangatu', 9),
     (1072, 'Porteirão', 9),
     (1073, 'Portelândia', 9),
     (1074, 'Posse', 9),
     (1075, 'Professor Jamil', 9),
     (1076, 'Quirinópolis', 9),
     (1077, 'Rialma', 9),
     (1078, 'Rianápolis', 9),
     (1079, 'Rio Quente', 9),
     (1080, 'Rio Verde', 9),
     (1081, 'Rubiataba', 9),
     (1082, 'Sanclerlândia', 9),
     (1083, 'Santa Bárbara de Goiás', 9),
     (1084, 'Santa Cruz de Goiás', 9),
     (1085, 'Santa Fé de Goiás', 9),
     (1086, 'Santa Helena de Goiás', 9),
     (1087, 'Santa Isabel', 9),
     (1088, 'Santa Rita do Araguaia', 9),
     (1089, 'Santa Rita do Novo Destino', 9),
     (1090, 'Santa Rosa de Goiás', 9),
     (1091, 'Santa Tereza de Goiás', 9),
     (1092, 'Santa Terezinha de Goiás', 9),
     (1093, 'Santo Antônio da Barra', 9),
     (1094, 'Santo Antônio de Goiás', 9),
     (1095, 'Santo Antônio do Descoberto', 9),
     (1096, 'São Domingos', 9),
     (1097, 'São Francisco de Goiás', 9),
     (1098, 'São João dAliança', 9),
     (1099, 'São João da Paraúna', 9),
     (1100, 'São Luís de Montes Belos', 9),
     (1101, 'São Luíz do Norte', 9),
     (1102, 'São Miguel do Araguaia', 9),
     (1103, 'São Miguel do Passa Quatro', 9),
     (1104, 'São Patrício', 9),
     (1105, 'São Simão', 9),
     (1106, 'Senador Canedo', 9),
     (1107, 'Serranópolis', 9),
     (1108, 'Silvânia', 9),
     (1109, 'Simolândia', 9),
     (1110, 'Sítio dAbadia', 9),
     (1111, 'Taquaral de Goiás', 9),
     (1112, 'Teresina de Goiás', 9),
     (1113, 'Terezópolis de Goiás', 9),
     (1114, 'Três Ranchos', 9),
     (1115, 'Trindade', 9),
     (1116, 'Trombas', 9),
     (1117, 'Turvânia', 9),
     (1118, 'Turvelândia', 9),
     (1119, 'Uirapuru', 9),
     (1120, 'Uruaçu', 9),
     (1121, 'Uruana', 9),
     (1122, 'Urutaí', 9),
     (1123, 'Valparaíso de Goiás', 9),
     (1124, 'Varjão', 9),
     (1125, 'Vianópolis', 9),
     (1126, 'Vicentinópolis', 9),
     (1127, 'Vila Boa', 9),
     (1128, 'Vila Propício', 9),
     (1129, 'Açailândia', 10),
     (1130, 'Afonso Cunha', 10),
     (1131, 'Água Doce do Maranhão', 10),
     (1132, 'Alcântara', 10),
     (1133, 'Aldeias Altas', 10),
     (1134, 'Altamira do Maranhão', 10),
     (1135, 'Alto Alegre do Maranhão', 10),
     (1136, 'Alto Alegre do Pindaré', 10),
     (1137, 'Alto Parnaíba', 10),
     (1138, 'Amapá do Maranhão', 10),
     (1139, 'Amarante do Maranhão', 10),
     (1140, 'Anajatuba', 10),
     (1141, 'Anapurus', 10),
     (1142, 'Apicum-Açu', 10),
     (1143, 'Araguanã', 10),
     (1144, 'Araioses', 10),
     (1145, 'Arame', 10),
     (1146, 'Arari', 10),
     (1147, 'Axixá', 10),
     (1148, 'Bacabal', 10),
     (1149, 'Bacabeira', 10),
     (1150, 'Bacuri', 10),
     (1151, 'Bacurituba', 10),
     (1152, 'Balsas', 10),
     (1153, 'Barão de Grajaú', 10),
     (1154, 'Barra do Corda', 10),
     (1155, 'Barreirinhas', 10),
     (1156, 'Bela Vista do Maranhão', 10),
     (1157, 'Belágua', 10),
     (1158, 'Benedito Leite', 10),
     (1159, 'Bequimão', 10),
     (1160, 'Bernardo do Mearim', 10),
     (1161, 'Boa Vista do Gurupi', 10),
     (1162, 'Bom Jardim', 10),
     (1163, 'Bom Jesus das Selvas', 10),
     (1164, 'Bom Lugar', 10),
     (1165, 'Brejo', 10),
     (1166, 'Brejo de Areia', 10),
     (1167, 'Buriti', 10),
     (1168, 'Buriti Bravo', 10),
     (1169, 'Buriticupu', 10),
     (1170, 'Buritirana', 10),
     (1171, 'Cachoeira Grande', 10),
     (1172, 'Cajapió', 10),
     (1173, 'Cajari', 10),
     (1174, 'Campestre do Maranhão', 10),
     (1175, 'Cândido Mendes', 10),
     (1176, 'Cantanhede', 10),
     (1177, 'Capinzal do Norte', 10),
     (1178, 'Carolina', 10),
     (1179, 'Carutapera', 10),
     (1180, 'Caxias', 10),
     (1181, 'Cedral', 10),
     (1182, 'Central do Maranhão', 10),
     (1183, 'Centro do Guilherme', 10),
     (1184, 'Centro Novo do Maranhão', 10),
     (1185, 'Chapadinha', 10),
     (1186, 'Cidelândia', 10),
     (1187, 'Codó', 10),
     (1188, 'Coelho Neto', 10),
     (1189, 'Colinas', 10),
     (1190, 'Conceição do Lago-Açu', 10),
     (1191, 'Coroatá', 10),
     (1192, 'Cururupu', 10),
     (1193, 'Davinópolis', 10),
     (1194, 'Dom Pedro', 10),
     (1195, 'Duque Bacelar', 10),
     (1196, 'Esperantinópolis', 10),
     (1197, 'Estreito', 10),
     (1198, 'Feira Nova do Maranhão', 10),
     (1199, 'Fernando Falcão', 10),
     (1200, 'Formosa da Serra Negra', 10),
     (1201, 'Fortaleza dos Nogueiras', 10),
     (1202, 'Fortuna', 10),
     (1203, 'Godofredo Viana', 10),
     (1204, 'Gonçalves Dias', 10),
     (1205, 'Governador Archer', 10),
     (1206, 'Governador Edison Lobão', 10),
     (1207, 'Governador Eugênio Barros', 10),
     (1208, 'Governador Luiz Rocha', 10),
     (1209, 'Governador Newton Bello', 10),
     (1210, 'Governador Nunes Freire', 10),
     (1211, 'Graça Aranha', 10),
     (1212, 'Grajaú', 10),
     (1213, 'Guimarães', 10),
     (1214, 'Humberto de Campos', 10),
     (1215, 'Icatu', 10),
     (1216, 'Igarapé do Meio', 10),
     (1217, 'Igarapé Grande', 10),
     (1218, 'Imperatriz', 10),
     (1219, 'Itaipava do Grajaú', 10),
     (1220, 'Itapecuru Mirim', 10),
     (1221, 'Itinga do Maranhão', 10),
     (1222, 'Jatobá', 10),
     (1223, 'Jenipapo dos Vieiras', 10),
     (1224, 'João Lisboa', 10),
     (1225, 'Joselândia', 10),
     (1226, 'Junco do Maranhão', 10),
     (1227, 'Lago da Pedra', 10),
     (1228, 'Lago do Junco', 10),
     (1229, 'Lago dos Rodrigues', 10),
     (1230, 'Lago Verde', 10),
     (1231, 'Lagoa do Mato', 10),
     (1232, 'Lagoa Grande do Maranhão', 10),
     (1233, 'Lajeado Novo', 10),
     (1234, 'Lima Campos', 10),
     (1235, 'Loreto', 10),
     (1236, 'Luís Domingues', 10),
     (1237, 'Magalhães de Almeida', 10),
     (1238, 'Maracaçumé', 10),
     (1239, 'Marajá do Sena', 10),
     (1240, 'Maranhãozinho', 10),
     (1241, 'Mata Roma', 10),
     (1242, 'Matinha', 10),
     (1243, 'Matões', 10),
     (1244, 'Matões do Norte', 10),
     (1245, 'Milagres do Maranhão', 10),
     (1246, 'Mirador', 10),
     (1247, 'Miranda do Norte', 10),
     (1248, 'Mirinzal', 10),
     (1249, 'Monção', 10),
     (1250, 'Montes Altos', 10),
     (1251, 'Morros', 10),
     (1252, 'Nina Rodrigues', 10),
     (1253, 'Nova Colinas', 10),
     (1254, 'Nova Iorque', 10),
     (1255, 'Nova Olinda do Maranhão', 10),
     (1256, 'Olho dÁgua das Cunhãs', 10),
     (1257, 'Olinda Nova do Maranhão', 10),
     (1258, 'Paço do Lumiar', 10),
     (1259, 'Palmeirândia', 10),
     (1260, 'Paraibano', 10),
     (1261, 'Parnarama', 10),
     (1262, 'Passagem Franca', 10),
     (1263, 'Pastos Bons', 10),
     (1264, 'Paulino Neves', 10),
     (1265, 'Paulo Ramos', 10),
     (1266, 'Pedreiras', 10),
     (1267, 'Pedro do Rosário', 10),
     (1268, 'Penalva', 10),
     (1269, 'Peri Mirim', 10),
     (1270, 'Peritoró', 10),
     (1271, 'Pindaré-Mirim', 10),
     (1272, 'Pinheiro', 10),
     (1273, 'Pio XII', 10),
     (1274, 'Pirapemas', 10),
     (1275, 'Poção de Pedras', 10),
     (1276, 'Porto Franco', 10),
     (1277, 'Porto Rico do Maranhão', 10),
     (1278, 'Presidente Dutra', 10),
     (1279, 'Presidente Juscelino', 10),
     (1280, 'Presidente Médici', 10),
     (1281, 'Presidente Sarney', 10),
     (1282, 'Presidente Vargas', 10),
     (1283, 'Primeira Cruz', 10),
     (1284, 'Raposa', 10),
     (1285, 'Riachão', 10),
     (1286, 'Ribamar Fiquene', 10),
     (1287, 'Rosário', 10),
     (1288, 'Sambaíba', 10),
     (1289, 'Santa Filomena do Maranhão', 10),
     (1290, 'Santa Helena', 10),
     (1291, 'Santa Inês', 10),
     (1292, 'Santa Luzia', 10),
     (1293, 'Santa Luzia do Paruá', 10),
     (1294, 'Santa Quitéria do Maranhão', 10),
     (1295, 'Santa Rita', 10),
     (1296, 'Santana do Maranhão', 10),
     (1297, 'Santo Amaro do Maranhão', 10),
     (1298, 'Santo Antônio dos Lopes', 10),
     (1299, 'São Benedito do Rio Preto', 10),
     (1300, 'São Bento', 10),
     (1301, 'São Bernardo', 10),
     (1302, 'São Domingos do Azeitão', 10),
     (1303, 'São Domingos do Maranhão', 10),
     (1304, 'São Félix de Balsas', 10),
     (1305, 'São Francisco do Brejão', 10),
     (1306, 'São Francisco do Maranhão', 10),
     (1307, 'São João Batista', 10),
     (1308, 'São João do Carú', 10),
     (1309, 'São João do Paraíso', 10),
     (1310, 'São João do Soter', 10),
     (1311, 'São João dos Patos', 10),
     (1312, 'São José de Ribamar', 10),
     (1313, 'São José dos Basílios', 10),
     (1314, 'São Luís', 10),
     (1315, 'São Luís Gonzaga do Maranhão', 10),
     (1316, 'São Mateus do Maranhão', 10),
     (1317, 'São Pedro da Água Branca', 10),
     (1318, 'São Pedro dos Crentes', 10),
     (1319, 'São Raimundo das Mangabeiras', 10),
     (1320, 'São Raimundo do Doca Bezerra', 10),
     (1321, 'São Roberto', 10),
     (1322, 'São Vicente Ferrer', 10),
     (1323, 'Satubinha', 10),
     (1324, 'Senador Alexandre Costa', 10),
     (1325, 'Senador La Rocque', 10),
     (1326, 'Serrano do Maranhão', 10),
     (1327, 'Sítio Novo', 10),
     (1328, 'Sucupira do Norte', 10),
     (1329, 'Sucupira do Riachão', 10),
     (1330, 'Tasso Fragoso', 10),
     (1331, 'Timbiras', 10),
     (1332, 'Timon', 10),
     (1333, 'Trizidela do Vale', 10),
     (1334, 'Tufilândia', 10),
     (1335, 'Tuntum', 10),
     (1336, 'Turiaçu', 10),
     (1337, 'Turilândia', 10),
     (1338, 'Tutóia', 10),
     (1339, 'Urbano Santos', 10),
     (1340, 'Vargem Grande', 10),
     (1341, 'Viana', 10),
     (1342, 'Vila Nova dos Martírios', 10),
     (1343, 'Vitória do Mearim', 10),
     (1344, 'Vitorino Freire', 10),
     (1345, 'Zé Doca', 10),
     (1346, 'Acorizal', 13),
     (1347, 'Água Boa', 13),
     (1348, 'Alta Floresta', 13),
     (1349, 'Alto Araguaia', 13),
     (1350, 'Alto Boa Vista', 13),
     (1351, 'Alto Garças', 13),
     (1352, 'Alto Paraguai', 13),
     (1353, 'Alto Taquari', 13),
     (1354, 'Apiacás', 13),
     (1355, 'Araguaiana', 13),
     (1356, 'Araguainha', 13),
     (1357, 'Araputanga', 13),
     (1358, 'Arenápolis', 13),
     (1359, 'Aripuanã', 13),
     (1360, 'Barão de Melgaço', 13),
     (1361, 'Barra do Bugres', 13),
     (1362, 'Barra do Garças', 13),
     (1363, 'Bom Jesus do Araguaia', 13),
     (1364, 'Brasnorte', 13),
     (1365, 'Cáceres', 13),
     (1366, 'Campinápolis', 13),
     (1367, 'Campo Novo do Parecis', 13),
     (1368, 'Campo Verde', 13),
     (1369, 'Campos de Júlio', 13),
     (1370, 'Canabrava do Norte', 13),
     (1371, 'Canarana', 13),
     (1372, 'Carlinda', 13),
     (1373, 'Castanheira', 13),
     (1374, 'Chapada dos Guimarães', 13),
     (1375, 'Cláudia', 13),
     (1376, 'Cocalinho', 13),
     (1377, 'Colíder', 13),
     (1378, 'Colniza', 13),
     (1379, 'Comodoro', 13),
     (1380, 'Confresa', 13),
     (1381, 'Conquista dOeste', 13),
     (1382, 'Cotriguaçu', 13),
     (1383, 'Cuiabá', 13),
     (1385, 'Curvelândia', 13),
     (1386, 'Denise', 13),
     (1387, 'Diamantino', 13),
     (1388, 'Dom Aquino', 13),
     (1389, 'Feliz Natal', 13),
     (1390, 'Figueirópolis dOeste', 13),
     (1391, 'Gaúcha do Norte', 13),
     (1392, 'General Carneiro', 13),
     (1393, 'Glória dOeste', 13),
     (1394, 'Guarantã do Norte', 13),
     (1395, 'Guiratinga', 13),
     (1396, 'Indiavaí', 13),
     (1397, 'Ipiranga do Norte', 13),
     (1398, 'Itanhangá', 13),
     (1399, 'Itaúba', 13),
     (1400, 'Itiquira', 13),
     (1401, 'Jaciara', 13),
     (1402, 'Jangada', 13),
     (1403, 'Jauru', 13),
     (1404, 'Juara', 13),
     (1405, 'Juína', 13),
     (1406, 'Juruena', 13),
     (1407, 'Juscimeira', 13),
     (1408, 'Lambari dOeste', 13),
     (1409, 'Lucas do Rio Verde', 13),
     (1410, 'Luciára', 13),
     (1411, 'Marcelândia', 13),
     (1412, 'Matupá', 13),
     (1413, 'Mirassol dOeste', 13),
     (1414, 'Nobres', 13),
     (1415, 'Nortelândia', 13),
     (1416, 'Nossa Senhora do Livramento', 13),
     (1417, 'Nova Bandeirantes', 13),
     (1418, 'Nova Brasilândia', 13),
     (1419, 'Nova Canaã do Norte', 13),
     (1420, 'Nova Guarita', 13),
     (1421, 'Nova Lacerda', 13),
     (1422, 'Nova Marilândia', 13),
     (1423, 'Nova Maringá', 13),
     (1424, 'Nova Monte verde', 13),
     (1425, 'Nova Mutum', 13),
     (1426, 'Nova Olímpia', 13),
     (1427, 'Nova Santa Helena', 13),
     (1428, 'Nova Ubiratã', 13),
     (1429, 'Nova Xavantina', 13),
     (1430, 'Novo Horizonte do Norte', 13),
     (1431, 'Novo Mundo', 13),
     (1432, 'Novo Santo Antônio', 13),
     (1433, 'Novo São Joaquim', 13),
     (1434, 'Paranaíta', 13),
     (1435, 'Paranatinga', 13),
     (1436, 'Pedra Preta', 13),
     (1437, 'Peixoto de Azevedo', 13),
     (1438, 'Planalto da Serra', 13),
     (1439, 'Poconé', 13),
     (1440, 'Pontal do Araguaia', 13),
     (1441, 'Ponte Branca', 13),
     (1442, 'Pontes e Lacerda', 13),
     (1443, 'Porto Alegre do Norte', 13),
     (1444, 'Porto dos Gaúchos', 13),
     (1445, 'Porto Esperidião', 13),
     (1446, 'Porto Estrela', 13),
     (1447, 'Poxoréo', 13),
     (1448, 'Primavera do Leste', 13),
     (1449, 'Querência', 13),
     (1450, 'Reserva do Cabaçal', 13),
     (1451, 'Ribeirão Cascalheira', 13),
     (1452, 'Ribeirãozinho', 13),
     (1453, 'Rio Branco', 13),
     (1454, 'Rondolândia', 13),
     (1455, 'Rondonópolis', 13),
     (1456, 'Rosário Oeste', 13),
     (1457, 'Salto do Céu', 13),
     (1458, 'Santa Carmem', 13),
     (1459, 'Santa Cruz do Xingu', 13),
     (1460, 'Santa Rita do Trivelato', 13),
     (1461, 'Santa Terezinha', 13),
     (1462, 'Santo Afonso', 13),
     (1463, 'Santo Antônio do Leste', 13),
     (1464, 'Santo Antônio do Leverger', 13),
     (1465, 'São Félix do Araguaia', 13),
     (1466, 'São José do Povo', 13),
     (1467, 'São José do Rio Claro', 13),
     (1468, 'São José do Xingu', 13),
     (1469, 'São José dos Quatro Marcos', 13),
     (1470, 'São Pedro da Cipa', 13),
     (1471, 'Sapezal', 13),
     (1472, 'Serra Nova Dourada', 13),
     (1473, 'Sinop', 13),
     (1474, 'Sorriso', 13),
     (1475, 'Tabaporã', 13),
     (1476, 'Tangará da Serra', 13),
     (1477, 'Tapurah', 13),
     (1478, 'Terra Nova do Norte', 13),
     (1479, 'Tesouro', 13),
     (1480, 'Torixoréu', 13),
     (1481, 'União do Sul', 13),
     (1482, 'Vale de São Domingos', 13),
     (1483, 'Várzea Grande', 13),
     (1484, 'Vera', 13),
     (1485, 'Vila Bela da Santíssima Trindade', 13),
     (1486, 'Vila Rica', 13),
     (1487, 'Água Clara', 12),
     (1488, 'Alcinópolis', 12),
     (1489, 'Amambaí', 12),
     (1490, 'Anastácio', 12),
     (1491, 'Anaurilândia', 12),
     (1492, 'Angélica', 12),
     (1493, 'Antônio João', 12),
     (1494, 'Aparecida do Taboado', 12),
     (1495, 'Aquidauana', 12),
     (1496, 'Aral Moreira', 12),
     (1497, 'Bandeirantes', 12),
     (1498, 'Bataguassu', 12),
     (1499, 'Bataiporã', 12),
     (1500, 'Bela Vista', 12),
     (1501, 'Bodoquena', 12),
     (1502, 'Bonito', 12),
     (1503, 'Brasilândia', 12),
     (1504, 'Caarapó', 12),
     (1505, 'Camapuã', 12),
     (1506, 'Campo Grande', 12),
     (1507, 'Caracol', 12),
     (1508, 'Cassilândia', 12),
     (1509, 'Chapadão do Sul', 12),
     (1510, 'Corguinho', 12),
     (1511, 'Coronel Sapucaia', 12),
     (1512, 'Corumbá', 12),
     (1513, 'Costa Rica', 12),
     (1514, 'Coxim', 12),
     (1515, 'Deodápolis', 12),
     (1516, 'Dois Irmãos do Buriti', 12),
     (1517, 'Douradina', 12),
     (1518, 'Dourados', 12),
     (1519, 'Eldorado', 12),
     (1520, 'Fátima do Sul', 12),
     (1521, 'Figueirão', 12),
     (1522, 'Glória de Dourados', 12),
     (1523, 'Guia Lopes da Laguna', 12),
     (1524, 'Iguatemi', 12),
     (1525, 'Inocência', 12),
     (1526, 'Itaporã', 12),
     (1527, 'Itaquiraí', 12),
     (1528, 'Ivinhema', 12),
     (1529, 'Japorã', 12),
     (1530, 'Jaraguari', 12),
     (1531, 'Jardim', 12),
     (1532, 'Jateí', 12),
     (1533, 'Juti', 12),
     (1534, 'Ladário', 12),
     (1535, 'Laguna Carapã', 12),
     (1536, 'Maracaju', 12),
     (1537, 'Miranda', 12),
     (1538, 'Mundo Novo', 12),
     (1539, 'Naviraí', 12),
     (1540, 'Nioaque', 12),
     (1541, 'Nova Alvorada do Sul', 12),
     (1542, 'Nova Andradina', 12),
     (1543, 'Novo Horizonte do Sul', 12),
     (1544, 'Paranaíba', 12),
     (1545, 'Paranhos', 12),
     (1546, 'Pedro Gomes', 12),
     (1547, 'Ponta Porã', 12),
     (1548, 'Porto Murtinho', 12),
     (1549, 'Ribas do Rio Pardo', 12),
     (1550, 'Rio Brilhante', 12),
     (1551, 'Rio Negro', 12),
     (1552, 'Rio Verde de Mato Grosso', 12),
     (1553, 'Rochedo', 12),
     (1554, 'Santa Rita do Pardo', 12),
     (1555, 'São Gabriel do Oeste', 12),
     (1556, 'Selvíria', 12),
     (1557, 'Sete Quedas', 12),
     (1558, 'Sidrolândia', 12),
     (1559, 'Sonora', 12),
     (1560, 'Tacuru', 12),
     (1561, 'Taquarussu', 12),
     (1562, 'Terenos', 12),
     (1563, 'Três Lagoas', 12),
     (1564, 'Vicentina', 12),
     (1565, 'Abadia dos Dourados', 11),
     (1566, 'Abaeté', 11),
     (1567, 'Abre Campo', 11),
     (1568, 'Acaiaca', 11),
     (1569, 'Açucena', 11),
     (1570, 'Água Boa', 11),
     (1571, 'Água Comprida', 11),
     (1572, 'Aguanil', 11),
     (1573, 'Águas Formosas', 11),
     (1574, 'Águas Vermelhas', 11),
     (1575, 'Aimorés', 11),
     (1576, 'Aiuruoca', 11),
     (1577, 'Alagoa', 11),
     (1578, 'Albertina', 11),
     (1579, 'Além Paraíba', 11),
     (1580, 'Alfenas', 11),
     (1581, 'Alfredo Vasconcelos', 11),
     (1582, 'Almenara', 11),
     (1583, 'Alpercata', 11),
     (1584, 'Alpinópolis', 11),
     (1585, 'Alterosa', 11),
     (1586, 'Alto Caparaó', 11),
     (1587, 'Alto Jequitibá', 11),
     (1588, 'Alto Rio Doce', 11),
     (1589, 'Alvarenga', 11),
     (1590, 'Alvinópolis', 11),
     (1591, 'Alvorada de Minas', 11),
     (1592, 'Amparo do Serra', 11),
     (1593, 'Andradas', 11),
     (1594, 'Andrelândia', 11),
     (1595, 'Angelândia', 11),
     (1596, 'Antônio Carlos', 11),
     (1597, 'Antônio Dias', 11),
     (1598, 'Antônio Prado de Minas', 11),
     (1599, 'Araçaí', 11),
     (1600, 'Aracitaba', 11),
     (1601, 'Araçuaí', 11),
     (1602, 'Araguari', 11),
     (1603, 'Arantina', 11),
     (1604, 'Araponga', 11),
     (1605, 'Araporã', 11),
     (1606, 'Arapuá', 11),
     (1607, 'Araújos', 11),
     (1608, 'Araxá', 11),
     (1609, 'Arceburgo', 11),
     (1610, 'Arcos', 11),
     (1611, 'Areado', 11),
     (1612, 'Argirita', 11),
     (1613, 'Aricanduva', 11),
     (1614, 'Arinos', 11),
     (1615, 'Astolfo Dutra', 11),
     (1616, 'Ataléia', 11),
     (1617, 'Augusto de Lima', 11),
     (1618, 'Baependi', 11),
     (1619, 'Baldim', 11),
     (1620, 'Bambuí', 11),
     (1621, 'Bandeira', 11),
     (1622, 'Bandeira do Sul', 11),
     (1623, 'Barão de Cocais', 11),
     (1624, 'Barão de Monte Alto', 11),
     (1625, 'Barbacena', 11),
     (1626, 'Barra Longa', 11),
     (1627, 'Barroso', 11),
     (1628, 'Bela Vista de Minas', 11),
     (1629, 'Belmiro Braga', 11),
     (1630, 'Belo Horizonte', 11),
     (1631, 'Belo Oriente', 11),
     (1632, 'Belo Vale', 11),
     (1633, 'Berilo', 11),
     (1634, 'Berizal', 11),
     (1635, 'Bertópolis', 11),
     (1636, 'Betim', 11),
     (1637, 'Bias Fortes', 11),
     (1638, 'Bicas', 11),
     (1639, 'Biquinhas', 11),
     (1640, 'Boa Esperança', 11),
     (1641, 'Bocaina de Minas', 11),
     (1642, 'Bocaiúva', 11),
     (1643, 'Bom Despacho', 11),
     (1644, 'Bom Jardim de Minas', 11),
     (1645, 'Bom Jesus da Penha', 11),
     (1646, 'Bom Jesus do Amparo', 11),
     (1647, 'Bom Jesus do Galho', 11),
     (1648, 'Bom Repouso', 11),
     (1649, 'Bom Sucesso', 11),
     (1650, 'Bonfim', 11),
     (1651, 'Bonfinópolis de Minas', 11),
     (1652, 'Bonito de Minas', 11),
     (1653, 'Borda da Mata', 11),
     (1654, 'Botelhos', 11),
     (1655, 'Botumirim', 11),
     (1656, 'Brás Pires', 11),
     (1657, 'Brasilândia de Minas', 11),
     (1658, 'Brasília de Minas', 11),
     (1659, 'Brasópolis', 11),
     (1660, 'Braúnas', 11),
     (1661, 'Brumadinho', 11),
     (1662, 'Bueno Brandão', 11),
     (1663, 'Buenópolis', 11),
     (1664, 'Bugre', 11),
     (1665, 'Buritis', 11),
     (1666, 'Buritizeiro', 11),
     (1667, 'Cabeceira Grande', 11),
     (1668, 'Cabo Verde', 11),
     (1669, 'Cachoeira da Prata', 11),
     (1670, 'Cachoeira de Minas', 11),
     (1671, 'Cachoeira de Pajeú', 11),
     (1672, 'Cachoeira Dourada', 11),
     (1673, 'Caetanópolis', 11),
     (1674, 'Caeté', 11),
     (1675, 'Caiana', 11),
     (1676, 'Cajuri', 11),
     (1677, 'Caldas', 11),
     (1678, 'Camacho', 11),
     (1679, 'Camanducaia', 11),
     (1680, 'Cambuí', 11),
     (1681, 'Cambuquira', 11),
     (1682, 'Campanário', 11),
     (1683, 'Campanha', 11),
     (1684, 'Campestre', 11),
     (1685, 'Campina Verde', 11),
     (1686, 'Campo Azul', 11),
     (1687, 'Campo Belo', 11),
     (1688, 'Campo do Meio', 11),
     (1689, 'Campo Florido', 11),
     (1690, 'Campos Altos', 11),
     (1691, 'Campos Gerais', 11),
     (1692, 'Cana Verde', 11),
     (1693, 'Canaã', 11),
     (1694, 'Canápolis', 11),
     (1695, 'Candeias', 11),
     (1696, 'Cantagalo', 11),
     (1697, 'Caparaó', 11),
     (1698, 'Capela Nova', 11),
     (1699, 'Capelinha', 11),
     (1700, 'Capetinga', 11),
     (1701, 'Capim Branco', 11),
     (1702, 'Capinópolis', 11),
     (1703, 'Capitão Andrade', 11),
     (1704, 'Capitão Enéas', 11),
     (1705, 'Capitólio', 11),
     (1706, 'Caputira', 11),
     (1707, 'Caraí', 11),
     (1708, 'Caranaíba', 11),
     (1709, 'Carandaí', 11),
     (1710, 'Carangola', 11),
     (1711, 'Caratinga', 11),
     (1712, 'Carbonita', 11),
     (1713, 'Careaçu', 11),
     (1714, 'Carlos Chagas', 11),
     (1715, 'Carmésia', 11),
     (1716, 'Carmo da Cachoeira', 11),
     (1717, 'Carmo da Mata', 11),
     (1718, 'Carmo de Minas', 11),
     (1719, 'Carmo do Cajuru', 11),
     (1720, 'Carmo do Paranaíba', 11),
     (1721, 'Carmo do Rio Claro', 11),
     (1722, 'Carmópolis de Minas', 11),
     (1723, 'Carneirinho', 11),
     (1724, 'Carrancas', 11),
     (1725, 'Carvalhópolis', 11),
     (1726, 'Carvalhos', 11),
     (1727, 'Casa Grande', 11),
     (1728, 'Cascalho Rico', 11),
     (1729, 'Cássia', 11),
     (1730, 'Cataguases', 11),
     (1731, 'Catas Altas', 11),
     (1732, 'Catas Altas da Noruega', 11),
     (1733, 'Catuji', 11),
     (1734, 'Catuti', 11),
     (1735, 'Caxambu', 11),
     (1736, 'Cedro do Abaeté', 11),
     (1737, 'Central de Minas', 11),
     (1738, 'Centralina', 11),
     (1739, 'Chácara', 11),
     (1740, 'Chalé', 11),
     (1741, 'Chapada do Norte', 11),
     (1742, 'Chapada Gaúcha', 11),
     (1743, 'Chiador', 11),
     (1744, 'Cipotânea', 11),
     (1745, 'Claraval', 11),
     (1746, 'Claro dos Poções', 11),
     (1747, 'Cláudio', 11),
     (1748, 'Coimbra', 11),
     (1749, 'Coluna', 11),
     (1750, 'Comendador Gomes', 11),
     (1751, 'Comercinho', 11),
     (1752, 'Conceição da Aparecida', 11),
     (1753, 'Conceição da Barra de Minas', 11),
     (1754, 'Conceição das Alagoas', 11),
     (1755, 'Conceição das Pedras', 11),
     (1756, 'Conceição de Ipanema', 11),
     (1757, 'Conceição do Mato Dentro', 11),
     (1758, 'Conceição do Pará', 11),
     (1759, 'Conceição do Rio Verde', 11),
     (1760, 'Conceição dos Ouros', 11),
     (1761, 'Cônego Marinho', 11),
     (1762, 'Confins', 11),
     (1763, 'Congonhal', 11),
     (1764, 'Congonhas', 11),
     (1765, 'Congonhas do Norte', 11),
     (1766, 'Conquista', 11),
     (1767, 'Conselheiro Lafaiete', 11),
     (1768, 'Conselheiro Pena', 11),
     (1769, 'Consolação', 11),
     (1770, 'Contagem', 11),
     (1771, 'Coqueiral', 11),
     (1772, 'Coração de Jesus', 11),
     (1773, 'Cordisburgo', 11),
     (1774, 'Cordislândia', 11),
     (1775, 'Corinto', 11),
     (1776, 'Coroaci', 11),
     (1777, 'Coromandel', 11),
     (1778, 'Coronel Fabriciano', 11),
     (1779, 'Coronel Murta', 11),
     (1780, 'Coronel Pacheco', 11),
     (1781, 'Coronel Xavier Chaves', 11),
     (1782, 'Córrego Danta', 11),
     (1783, 'Córrego do Bom Jesus', 11),
     (1784, 'Córrego Fundo', 11),
     (1785, 'Córrego Novo', 11),
     (1786, 'Couto de Magalhães de Minas', 11),
     (1787, 'Crisólita', 11),
     (1788, 'Cristais', 11),
     (1789, 'Cristália', 11),
     (1790, 'Cristiano Otoni', 11),
     (1791, 'Cristina', 11),
     (1792, 'Crucilândia', 11),
     (1793, 'Cruzeiro da Fortaleza', 11),
     (1794, 'Cruzília', 11),
     (1795, 'Cuparaque', 11),
     (1796, 'Curral de Dentro', 11),
     (1797, 'Curvelo', 11),
     (1798, 'Datas', 11),
     (1799, 'Delfim Moreira', 11),
     (1800, 'Delfinópolis', 11),
     (1801, 'Delta', 11),
     (1802, 'Descoberto', 11),
     (1803, 'Desterro de Entre Rios', 11),
     (1804, 'Desterro do Melo', 11),
     (1805, 'Diamantina', 11),
     (1806, 'Diogo de Vasconcelos', 11),
     (1807, 'Dionísio', 11),
     (1808, 'Divinésia', 11),
     (1809, 'Divino', 11),
     (1810, 'Divino das Laranjeiras', 11),
     (1811, 'Divinolândia de Minas', 11),
     (1812, 'Divinópolis', 11),
     (1813, 'Divisa Alegre', 11),
     (1814, 'Divisa Nova', 11),
     (1815, 'Divisópolis', 11),
     (1816, 'Dom Bosco', 11),
     (1817, 'Dom Cavati', 11),
     (1818, 'Dom Joaquim', 11),
     (1819, 'Dom Silvério', 11),
     (1820, 'Dom Viçoso', 11),
     (1821, 'Dona Eusébia', 11),
     (1822, 'Dores de Campos', 11),
     (1823, 'Dores de Guanhães', 11),
     (1824, 'Dores do Indaiá', 11),
     (1825, 'Dores do Turvo', 11),
     (1826, 'Doresópolis', 11),
     (1827, 'Douradoquara', 11),
     (1828, 'Durandé', 11),
     (1829, 'Elói Mendes', 11),
     (1830, 'Engenheiro Caldas', 11),
     (1831, 'Engenheiro Navarro', 11),
     (1832, 'Entre Folhas', 11),
     (1833, 'Entre Rios de Minas', 11),
     (1834, 'Ervália', 11),
     (1835, 'Esmeraldas', 11),
     (1836, 'Espera Feliz', 11),
     (1837, 'Espinosa', 11),
     (1838, 'Espírito Santo do Dourado', 11),
     (1839, 'Estiva', 11),
     (1840, 'Estrela Dalva', 11),
     (1841, 'Estrela do Indaiá', 11),
     (1842, 'Estrela do Sul', 11),
     (1843, 'Eugenópolis', 11),
     (1844, 'Ewbank da Câmara', 11),
     (1845, 'Extrema', 11),
     (1846, 'Fama', 11),
     (1847, 'Faria Lemos', 11),
     (1848, 'Felício dos Santos', 11),
     (1849, 'Felisburgo', 11),
     (1850, 'Felixlândia', 11),
     (1851, 'Fernandes Tourinho', 11),
     (1852, 'Ferros', 11),
     (1853, 'Fervedouro', 11),
     (1854, 'Florestal', 11),
     (1855, 'Formiga', 11),
     (1856, 'Formoso', 11),
     (1857, 'Fortaleza de Minas', 11),
     (1858, 'Fortuna de Minas', 11),
     (1859, 'Francisco Badaró', 11),
     (1860, 'Francisco Dumont', 11),
     (1861, 'Francisco Sá', 11),
     (1862, 'Franciscópolis', 11),
     (1863, 'Frei Gaspar', 11),
     (1864, 'Frei Inocêncio', 11),
     (1865, 'Frei Lagonegro', 11),
     (1866, 'Fronteira', 11),
     (1867, 'Fronteira dos Vales', 11),
     (1868, 'Fruta de Leite', 11),
     (1869, 'Frutal', 11),
     (1870, 'Funilândia', 11),
     (1871, 'Galiléia', 11),
     (1872, 'Gameleiras', 11),
     (1873, 'Glaucilândia', 11),
     (1874, 'Goiabeira', 11),
     (1875, 'Goianá', 11),
     (1876, 'Gonçalves', 11),
     (1877, 'Gonzaga', 11),
     (1878, 'Gouveia', 11),
     (1879, 'Governador Valadares', 11),
     (1880, 'Grão Mogol', 11),
     (1881, 'Grupiara', 11),
     (1882, 'Guanhães', 11),
     (1883, 'Guapé', 11),
     (1884, 'Guaraciaba', 11),
     (1885, 'Guaraciama', 11),
     (1886, 'Guaranésia', 11),
     (1887, 'Guarani', 11),
     (1888, 'Guarará', 11),
     (1889, 'Guarda-Mor', 11),
     (1890, 'Guaxupé', 11),
     (1891, 'Guidoval', 11),
     (1892, 'Guimarânia', 11),
     (1893, 'Guiricema', 11),
     (1894, 'Gurinhatã', 11),
     (1895, 'Heliodora', 11),
     (1896, 'Iapu', 11),
     (1897, 'Ibertioga', 11),
     (1898, 'Ibiá', 11),
     (1899, 'Ibiaí', 11),
     (1900, 'Ibiracatu', 11),
     (1901, 'Ibiraci', 11),
     (1902, 'Ibirité', 11),
     (1903, 'Ibitiúra de Minas', 11),
     (1904, 'Ibituruna', 11),
     (1905, 'Icaraí de Minas', 11),
     (1906, 'Igarapé', 11),
     (1907, 'Igaratinga', 11),
     (1908, 'Iguatama', 11),
     (1909, 'Ijaci', 11),
     (1910, 'Ilicínea', 11),
     (1911, 'Imbé de Minas', 11),
     (1912, 'Inconfidentes', 11),
     (1913, 'Indaiabira', 11),
     (1914, 'Indianópolis', 11),
     (1915, 'Ingaí', 11),
     (1916, 'Inhapim', 11),
     (1917, 'Inhaúma', 11),
     (1918, 'Inimutaba', 11),
     (1919, 'Ipaba', 11),
     (1920, 'Ipanema', 11),
     (1921, 'Ipatinga', 11),
     (1922, 'Ipiaçu', 11),
     (1923, 'Ipuiúna', 11),
     (1924, 'Iraí de Minas', 11),
     (1925, 'Itabira', 11),
     (1926, 'Itabirinha de Mantena', 11),
     (1927, 'Itabirito', 11),
     (1928, 'Itacambira', 11),
     (1929, 'Itacarambi', 11),
     (1930, 'Itaguara', 11),
     (1931, 'Itaipé', 11),
     (1932, 'Itajubá', 11),
     (1933, 'Itamarandiba', 11),
     (1934, 'Itamarati de Minas', 11),
     (1935, 'Itambacuri', 11),
     (1936, 'Itambé do Mato Dentro', 11),
     (1937, 'Itamogi', 11),
     (1938, 'Itamonte', 11),
     (1939, 'Itanhandu', 11),
     (1940, 'Itanhomi', 11),
     (1941, 'Itaobim', 11),
     (1942, 'Itapagipe', 11),
     (1943, 'Itapecerica', 11),
     (1944, 'Itapeva', 11),
     (1945, 'Itatiaiuçu', 11),
     (1946, 'Itaú de Minas', 11),
     (1947, 'Itaúna', 11),
     (1948, 'Itaverava', 11),
     (1949, 'Itinga', 11),
     (1950, 'Itueta', 11),
     (1951, 'Ituiutaba', 11),
     (1952, 'Itumirim', 11),
     (1953, 'Iturama', 11),
     (1954, 'Itutinga', 11),
     (1955, 'Jaboticatubas', 11),
     (1956, 'Jacinto', 11),
     (1957, 'Jacuí', 11),
     (1958, 'Jacutinga', 11),
     (1959, 'Jaguaraçu', 11),
     (1960, 'Jaíba', 11),
     (1961, 'Jampruca', 11),
     (1962, 'Janaúba', 11),
     (1963, 'Januária', 11),
     (1964, 'Japaraíba', 11),
     (1965, 'Japonvar', 11),
     (1966, 'Jeceaba', 11),
     (1967, 'Jenipapo de Minas', 11),
     (1968, 'Jequeri', 11),
     (1969, 'Jequitaí', 11),
     (1970, 'Jequitibá', 11),
     (1971, 'Jequitinhonha', 11),
     (1972, 'Jesuânia', 11),
     (1973, 'Joaíma', 11),
     (1974, 'Joanésia', 11),
     (1975, 'João Monlevade', 11),
     (1976, 'João Pinheiro', 11),
     (1977, 'Joaquim Felício', 11),
     (1978, 'Jordânia', 11),
     (1979, 'José Gonçalves de Minas', 11),
     (1980, 'José Raydan', 11),
     (1981, 'Josenópolis', 11),
     (1982, 'Juatuba', 11),
     (1983, 'Juiz de Fora', 11),
     (1984, 'Juramento', 11),
     (1985, 'Juruaia', 11),
     (1986, 'Juvenília', 11),
     (1987, 'Ladainha', 11),
     (1988, 'Lagamar', 11),
     (1989, 'Lagoa da Prata', 11),
     (1990, 'Lagoa dos Patos', 11),
     (1991, 'Lagoa Dourada', 11),
     (1992, 'Lagoa Formosa', 11),
     (1993, 'Lagoa Grande', 11),
     (1994, 'Lagoa Santa', 11),
     (1995, 'Lajinha', 11),
     (1996, 'Lambari', 11),
     (1997, 'Lamim', 11),
     (1998, 'Laranjal', 11),
     (1999, 'Lassance', 11),
     (2000, 'Lavras', 11),
     (2001, 'Leandro Ferreira', 11),
     (2002, 'Leme do Prado', 11),
     (2003, 'Leopoldina', 11),
     (2004, 'Liberdade', 11),
     (2005, 'Lima Duarte', 11),
     (2006, 'Limeira do Oeste', 11),
     (2007, 'Lontra', 11),
     (2008, 'Luisburgo', 11),
     (2009, 'Luislândia', 11),
     (2010, 'Luminárias', 11),
     (2011, 'Luz', 11),
     (2012, 'Machacalis', 11),
     (2013, 'Machado', 11),
     (2014, 'Madre de Deus de Minas', 11),
     (2015, 'Malacacheta', 11),
     (2016, 'Mamonas', 11),
     (2017, 'Manga', 11),
     (2018, 'Manhuaçu', 11),
     (2019, 'Manhumirim', 11),
     (2020, 'Mantena', 11),
     (2021, 'Mar de Espanha', 11),
     (2022, 'Maravilhas', 11),
     (2023, 'Maria da Fé', 11),
     (2024, 'Mariana', 11),
     (2025, 'Marilac', 11),
     (2026, 'Mário Campos', 11),
     (2027, 'Maripá de Minas', 11),
     (2028, 'Marliéria', 11),
     (2029, 'Marmelópolis', 11),
     (2030, 'Martinho Campos', 11),
     (2031, 'Martins Soares', 11),
     (2032, 'Mata Verde', 11),
     (2033, 'Materlândia', 11),
     (2034, 'Mateus Leme', 11),
     (2035, 'Mathias Lobato', 11),
     (2036, 'Matias Barbosa', 11),
     (2037, 'Matias Cardoso', 11),
     (2038, 'Matipó', 11),
     (2039, 'Mato Verde', 11),
     (2040, 'Matozinhos', 11),
     (2041, 'Matutina', 11),
     (2042, 'Medeiros', 11),
     (2043, 'Medina', 11),
     (2044, 'Mendes Pimentel', 11),
     (2045, 'Mercês', 11),
     (2046, 'Mesquita', 11),
     (2047, 'Minas Novas', 11),
     (2048, 'Minduri', 11),
     (2049, 'Mirabela', 11),
     (2050, 'Miradouro', 11),
     (2051, 'Miraí', 11),
     (2052, 'Miravânia', 11),
     (2053, 'Moeda', 11),
     (2054, 'Moema', 11),
     (2055, 'Monjolos', 11),
     (2056, 'Monsenhor Paulo', 11),
     (2057, 'Montalvânia', 11),
     (2058, 'Monte Alegre de Minas', 11),
     (2059, 'Monte Azul', 11),
     (2060, 'Monte Belo', 11),
     (2061, 'Monte Carmelo', 11),
     (2062, 'Monte Formoso', 11),
     (2063, 'Monte Santo de Minas', 11),
     (2064, 'Monte Sião', 11),
     (2065, 'Montes Claros', 11),
     (2066, 'Montezuma', 11),
     (2067, 'Morada Nova de Minas', 11),
     (2068, 'Morro da Garça', 11),
     (2069, 'Morro do Pilar', 11),
     (2070, 'Munhoz', 11),
     (2071, 'Muriaé', 11),
     (2072, 'Mutum', 11),
     (2073, 'Muzambinho', 11),
     (2074, 'Nacip Raydan', 11),
     (2075, 'Nanuque', 11),
     (2076, 'Naque', 11),
     (2077, 'Natalândia', 11),
     (2078, 'Natércia', 11),
     (2079, 'Nazareno', 11),
     (2080, 'Nepomuceno', 11),
     (2081, 'Ninheira', 11),
     (2082, 'Nova Belém', 11),
     (2083, 'Nova Era', 11),
     (2084, 'Nova Lima', 11),
     (2085, 'Nova Módica', 11),
     (2086, 'Nova Ponte', 11),
     (2087, 'Nova Porteirinha', 11),
     (2088, 'Nova Resende', 11),
     (2089, 'Nova Serrana', 11),
     (2090, 'Nova União', 11),
     (2091, 'Novo Cruzeiro', 11),
     (2092, 'Novo Oriente de Minas', 11),
     (2093, 'Novorizonte', 11),
     (2094, 'Olaria', 11),
     (2095, 'Olhos-dÁgua', 11),
     (2096, 'Olímpio Noronha', 11),
     (2097, 'Oliveira', 11),
     (2098, 'Oliveira Fortes', 11),
     (2099, 'Onça de Pitangui', 11),
     (2100, 'Oratórios', 11),
     (2101, 'Orizânia', 11),
     (2102, 'Ouro Branco', 11),
     (2103, 'Ouro Fino', 11),
     (2104, 'Ouro Preto', 11),
     (2105, 'Ouro Verde de Minas', 11),
     (2106, 'Padre Carvalho', 11),
     (2107, 'Padre Paraíso', 11),
     (2108, 'Pai Pedro', 11),
     (2109, 'Paineiras', 11),
     (2110, 'Pains', 11),
     (2111, 'Paiva', 11),
     (2112, 'Palma', 11),
     (2113, 'Palmópolis', 11),
     (2114, 'Papagaios', 11),
     (2115, 'Pará de Minas', 11),
     (2116, 'Paracatu', 11),
     (2117, 'Paraguaçu', 11),
     (2118, 'Paraisópolis', 11),
     (2119, 'Paraopeba', 11),
     (2120, 'Passa Quatro', 11),
     (2121, 'Passa Tempo', 11),
     (2122, 'Passabém', 11),
     (2123, 'Passa-Vinte', 11),
     (2124, 'Passos', 11),
     (2125, 'Patis', 11),
     (2126, 'Patos de Minas', 11),
     (2127, 'Patrocínio', 11),
     (2128, 'Patrocínio do Muriaé', 11),
     (2129, 'Paula Cândido', 11),
     (2130, 'Paulistas', 11),
     (2131, 'Pavão', 11),
     (2132, 'Peçanha', 11),
     (2133, 'Pedra Azul', 11),
     (2134, 'Pedra Bonita', 11),
     (2135, 'Pedra do Anta', 11),
     (2136, 'Pedra do Indaiá', 11),
     (2137, 'Pedra Dourada', 11),
     (2138, 'Pedralva', 11),
     (2139, 'Pedras de Maria da Cruz', 11),
     (2140, 'Pedrinópolis', 11),
     (2141, 'Pedro Leopoldo', 11),
     (2142, 'Pedro Teixeira', 11),
     (2143, 'Pequeri', 11),
     (2144, 'Pequi', 11),
     (2145, 'Perdigão', 11),
     (2146, 'Perdizes', 11),
     (2147, 'Perdões', 11),
     (2148, 'Periquito', 11),
     (2149, 'Pescador', 11),
     (2150, 'Piau', 11),
     (2151, 'Piedade de Caratinga', 11),
     (2152, 'Piedade de Ponte Nova', 11),
     (2153, 'Piedade do Rio Grande', 11),
     (2154, 'Piedade dos Gerais', 11),
     (2155, 'Pimenta', 11),
     (2156, 'Pingo-dÁgua', 11),
     (2157, 'Pintópolis', 11),
     (2158, 'Piracema', 11),
     (2159, 'Pirajuba', 11),
     (2160, 'Piranga', 11),
     (2161, 'Piranguçu', 11),
     (2162, 'Piranguinho', 11),
     (2163, 'Pirapetinga', 11),
     (2164, 'Pirapora', 11),
     (2165, 'Piraúba', 11),
     (2166, 'Pitangui', 11),
     (2167, 'Piumhi', 11),
     (2168, 'Planura', 11),
     (2169, 'Poço Fundo', 11),
     (2170, 'Poços de Caldas', 11),
     (2171, 'Pocrane', 11),
     (2172, 'Pompéu', 11),
     (2173, 'Ponte Nova', 11),
     (2174, 'Ponto Chique', 11),
     (2175, 'Ponto dos Volantes', 11),
     (2176, 'Porteirinha', 11),
     (2177, 'Porto Firme', 11),
     (2178, 'Poté', 11),
     (2179, 'Pouso Alegre', 11),
     (2180, 'Pouso Alto', 11),
     (2181, 'Prados', 11),
     (2182, 'Prata', 11),
     (2183, 'Pratápolis', 11),
     (2184, 'Pratinha', 11),
     (2185, 'Presidente Bernardes', 11),
     (2186, 'Presidente Juscelino', 11),
     (2187, 'Presidente Kubitschek', 11),
     (2188, 'Presidente Olegário', 11),
     (2189, 'Prudente de Morais', 11),
     (2190, 'Quartel Geral', 11),
     (2191, 'Queluzito', 11),
     (2192, 'Raposos', 11),
     (2193, 'Raul Soares', 11),
     (2194, 'Recreio', 11),
     (2195, 'Reduto', 11),
     (2196, 'Resende Costa', 11),
     (2197, 'Resplendor', 11),
     (2198, 'Ressaquinha', 11),
     (2199, 'Riachinho', 11),
     (2200, 'Riacho dos Machados', 11),
     (2201, 'Ribeirão das Neves', 11),
     (2202, 'Ribeirão Vermelho', 11),
     (2203, 'Rio Acima', 11),
     (2204, 'Rio Casca', 11),
     (2205, 'Rio do Prado', 11),
     (2206, 'Rio Doce', 11),
     (2207, 'Rio Espera', 11),
     (2208, 'Rio Manso', 11),
     (2209, 'Rio Novo', 11),
     (2210, 'Rio Paranaíba', 11),
     (2211, 'Rio Pardo de Minas', 11),
     (2212, 'Rio Piracicaba', 11),
     (2213, 'Rio Pomba', 11),
     (2214, 'Rio Preto', 11),
     (2215, 'Rio Vermelho', 11),
     (2216, 'Ritápolis', 11),
     (2217, 'Rochedo de Minas', 11),
     (2218, 'Rodeiro', 11),
     (2219, 'Romaria', 11),
     (2220, 'Rosário da Limeira', 11),
     (2221, 'Rubelita', 11),
     (2222, 'Rubim', 11),
     (2223, 'Sabará', 11),
     (2224, 'Sabinópolis', 11),
     (2225, 'Sacramento', 11),
     (2226, 'Salinas', 11),
     (2227, 'Salto da Divisa', 11),
     (2228, 'Santa Bárbara', 11),
     (2229, 'Santa Bárbara do Leste', 11),
     (2230, 'Santa Bárbara do Monte Verde', 11),
     (2231, 'Santa Bárbara do Tugúrio', 11),
     (2232, 'Santa Cruz de Minas', 11),
     (2233, 'Santa Cruz de Salinas', 11),
     (2234, 'Santa Cruz do Escalvado', 11),
     (2235, 'Santa Efigênia de Minas', 11),
     (2236, 'Santa Fé de Minas', 11),
     (2237, 'Santa Helena de Minas', 11),
     (2238, 'Santa Juliana', 11),
     (2239, 'Santa Luzia', 11),
     (2240, 'Santa Margarida', 11),
     (2241, 'Santa Maria de Itabira', 11),
     (2242, 'Santa Maria do Salto', 11),
     (2243, 'Santa Maria do Suaçuí', 11),
     (2244, 'Santa Rita de Caldas', 11),
     (2245, 'Santa Rita de Ibitipoca', 11),
     (2246, 'Santa Rita de Jacutinga', 11),
     (2247, 'Santa Rita de Minas', 11),
     (2248, 'Santa Rita do Itueto', 11),
     (2249, 'Santa Rita do Sapucaí', 11),
     (2250, 'Santa Rosa da Serra', 11),
     (2251, 'Santa Vitória', 11),
     (2252, 'Santana da Vargem', 11),
     (2253, 'Santana de Cataguases', 11),
     (2254, 'Santana de Pirapama', 11),
     (2255, 'Santana do Deserto', 11),
     (2256, 'Santana do Garambéu', 11),
     (2257, 'Santana do Jacaré', 11),
     (2258, 'Santana do Manhuaçu', 11),
     (2259, 'Santana do Paraíso', 11),
     (2260, 'Santana do Riacho', 11),
     (2261, 'Santana dos Montes', 11),
     (2262, 'Santo Antônio do Amparo', 11),
     (2263, 'Santo Antônio do Aventureiro', 11),
     (2264, 'Santo Antônio do Grama', 11),
     (2265, 'Santo Antônio do Itambé', 11),
     (2266, 'Santo Antônio do Jacinto', 11),
     (2267, 'Santo Antônio do Monte', 11),
     (2268, 'Santo Antônio do Retiro', 11),
     (2269, 'Santo Antônio do Rio Abaixo', 11),
     (2270, 'Santo Hipólito', 11),
     (2271, 'Santos Dumont', 11),
     (2272, 'São Bento Abade', 11),
     (2273, 'São Brás do Suaçuí', 11),
     (2274, 'São Domingos das Dores', 11),
     (2275, 'São Domingos do Prata', 11),
     (2276, 'São Félix de Minas', 11),
     (2277, 'São Francisco', 11),
     (2278, 'São Francisco de Paula', 11),
     (2279, 'São Francisco de Sales', 11),
     (2280, 'São Francisco do Glória', 11),
     (2281, 'São Geraldo', 11),
     (2282, 'São Geraldo da Piedade', 11),
     (2283, 'São Geraldo do Baixio', 11),
     (2284, 'São Gonçalo do Abaeté', 11),
     (2285, 'São Gonçalo do Pará', 11),
     (2286, 'São Gonçalo do Rio Abaixo', 11),
     (2287, 'São Gonçalo do Rio Preto', 11),
     (2288, 'São Gonçalo do Sapucaí', 11),
     (2289, 'São Gotardo', 11),
     (2290, 'São João Batista do Glória', 11),
     (2291, 'São João da Lagoa', 11),
     (2292, 'São João da Mata', 11),
     (2293, 'São João da Ponte', 11),
     (2294, 'São João das Missões', 11),
     (2295, 'São João del Rei', 11),
     (2296, 'São João do Manhuaçu', 11),
     (2297, 'São João do Manteninha', 11),
     (2298, 'São João do Oriente', 11),
     (2299, 'São João do Pacuí', 11),
     (2300, 'São João do Paraíso', 11),
     (2301, 'São João Evangelista', 11),
     (2302, 'São João Nepomuceno', 11),
     (2303, 'São Joaquim de Bicas', 11),
     (2304, 'São José da Barra', 11),
     (2305, 'São José da Lapa', 11),
     (2306, 'São José da Safira', 11),
     (2307, 'São José da Varginha', 11),
     (2308, 'São José do Alegre', 11),
     (2309, 'São José do Divino', 11),
     (2310, 'São José do Goiabal', 11),
     (2311, 'São José do Jacuri', 11),
     (2312, 'São José do Mantimento', 11),
     (2313, 'São Lourenço', 11),
     (2314, 'São Miguel do Anta', 11),
     (2315, 'São Pedro da União', 11),
     (2316, 'São Pedro do Suaçuí', 11),
     (2317, 'São Pedro dos Ferros', 11),
     (2318, 'São Romão', 11),
     (2319, 'São Roque de Minas', 11),
     (2320, 'São Sebastião da Bela Vista', 11),
     (2321, 'São Sebastião da Vargem Alegre', 11),
     (2322, 'São Sebastião do Anta', 11),
     (2323, 'São Sebastião do Maranhão', 11),
     (2324, 'São Sebastião do Oeste', 11),
     (2325, 'São Sebastião do Paraíso', 11),
     (2326, 'São Sebastião do Rio Preto', 11),
     (2327, 'São Sebastião do Rio Verde', 11),
     (2328, 'São Thomé das Letras', 11),
     (2329, 'São Tiago', 11),
     (2330, 'São Tomás de Aquino', 11),
     (2331, 'São Vicente de Minas', 11),
     (2332, 'Sapucaí-Mirim', 11),
     (2333, 'Sardoá', 11),
     (2334, 'Sarzedo', 11),
     (2335, 'Sem-Peixe', 11),
     (2336, 'Senador Amaral', 11),
     (2337, 'Senador Cortes', 11),
     (2338, 'Senador Firmino', 11),
     (2339, 'Senador José Bento', 11),
     (2340, 'Senador Modestino Gonçalves', 11),
     (2341, 'Senhora de Oliveira', 11),
     (2342, 'Senhora do Porto', 11),
     (2343, 'Senhora dos Remédios', 11),
     (2344, 'Sericita', 11),
     (2345, 'Seritinga', 11),
     (2346, 'Serra Azul de Minas', 11),
     (2347, 'Serra da Saudade', 11),
     (2348, 'Serra do Salitre', 11),
     (2349, 'Serra dos Aimorés', 11),
     (2350, 'Serrania', 11),
     (2351, 'Serranópolis de Minas', 11),
     (2352, 'Serranos', 11),
     (2353, 'Serro', 11),
     (2354, 'Sete Lagoas', 11),
     (2355, 'Setubinha', 11),
     (2356, 'Silveirânia', 11),
     (2357, 'Silvianópolis', 11),
     (2358, 'Simão Pereira', 11),
     (2359, 'Simonésia', 11),
     (2360, 'Sobrália', 11),
     (2361, 'Soledade de Minas', 11),
     (2362, 'Tabuleiro', 11),
     (2363, 'Taiobeiras', 11),
     (2364, 'Taparuba', 11),
     (2365, 'Tapira', 11),
     (2366, 'Tapiraí', 11),
     (2367, 'Taquaraçu de Minas', 11),
     (2368, 'Tarumirim', 11),
     (2369, 'Teixeiras', 11),
     (2370, 'Teófilo Otoni', 11),
     (2371, 'Timóteo', 11),
     (2372, 'Tiradentes', 11),
     (2373, 'Tiros', 11),
     (2374, 'Tocantins', 11),
     (2375, 'Tocos do Moji', 11),
     (2376, 'Toledo', 11),
     (2377, 'Tombos', 11),
     (2378, 'Três Corações', 11),
     (2379, 'Três Marias', 11),
     (2380, 'Três Pontas', 11),
     (2381, 'Tumiritinga', 11),
     (2382, 'Tupaciguara', 11),
     (2383, 'Turmalina', 11),
     (2384, 'Turvolândia', 11),
     (2385, 'Ubá', 11),
     (2386, 'Ubaí', 11),
     (2387, 'Ubaporanga', 11),
     (2388, 'Uberaba', 11),
     (2389, 'Uberlândia', 11),
     (2390, 'Umburatiba', 11),
     (2391, 'Unaí', 11),
     (2392, 'União de Minas', 11),
     (2393, 'Uruana de Minas', 11),
     (2394, 'Urucânia', 11),
     (2395, 'Urucuia', 11),
     (2396, 'Vargem Alegre', 11),
     (2397, 'Vargem Bonita', 11),
     (2398, 'Vargem Grande do Rio Pardo', 11),
     (2399, 'Varginha', 11),
     (2400, 'Varjão de Minas', 11),
     (2401, 'Várzea da Palma', 11),
     (2402, 'Varzelândia', 11),
     (2403, 'Vazante', 11),
     (2404, 'Verdelândia', 11),
     (2405, 'Veredinha', 11),
     (2406, 'Veríssimo', 11),
     (2407, 'Vermelho Novo', 11),
     (2408, 'Vespasiano', 11),
     (2409, 'Viçosa', 11),
     (2410, 'Vieiras', 11),
     (2411, 'Virgem da Lapa', 11),
     (2412, 'Virgínia', 11),
     (2413, 'Virginópolis', 11),
     (2414, 'Virgolândia', 11),
     (2415, 'Visconde do Rio Branco', 11),
     (2416, 'Volta Grande', 11),
     (2417, 'Wenceslau Braz', 11),
     (2418, 'Abaetetuba', 14),
     (2419, 'Abel Figueiredo', 14),
     (2420, 'Acará', 14),
     (2421, 'Afuá', 14),
     (2422, 'Água Azul do Norte', 14),
     (2423, 'Alenquer', 14),
     (2424, 'Almeirim', 14),
     (2425, 'Altamira', 14),
     (2426, 'Anajás', 14),
     (2427, 'Ananindeua', 14),
     (2428, 'Anapu', 14),
     (2429, 'Augusto Corrêa', 14),
     (2430, 'Aurora do Pará', 14),
     (2431, 'Aveiro', 14),
     (2432, 'Bagre', 14),
     (2433, 'Baião', 14),
     (2434, 'Bannach', 14),
     (2435, 'Barcarena', 14),
     (2436, 'Belém', 14),
     (2437, 'Belterra', 14),
     (2438, 'Benevides', 14),
     (2439, 'Bom Jesus do Tocantins', 14),
     (2440, 'Bonito', 14),
     (2441, 'Bragança', 14),
     (2442, 'Brasil Novo', 14),
     (2443, 'Brejo Grande do Araguaia', 14),
     (2444, 'Breu Branco', 14),
     (2445, 'Breves', 14),
     (2446, 'Bujaru', 14),
     (2447, 'Cachoeira do Arari', 14),
     (2448, 'Cachoeira do Piriá', 14),
     (2449, 'Cametá', 14),
     (2450, 'Canaã dos Carajás', 14),
     (2451, 'Capanema', 14),
     (2452, 'Capitão Poço', 14),
     (2453, 'Castanhal', 14),
     (2454, 'Chaves', 14),
     (2455, 'Colares', 14),
     (2456, 'Conceição do Araguaia', 14),
     (2457, 'Concórdia do Pará', 14),
     (2458, 'Cumaru do Norte', 14),
     (2459, 'Curionópolis', 14),
     (2460, 'Curralinho', 14),
     (2461, 'Curuá', 14),
     (2462, 'Curuçá', 14),
     (2463, 'Dom Eliseu', 14),
     (2464, 'Eldorado dos Carajás', 14),
     (2465, 'Faro', 14),
     (2466, 'Floresta do Araguaia', 14),
     (2467, 'Garrafão do Norte', 14),
     (2468, 'Goianésia do Pará', 14),
     (2469, 'Gurupá', 14),
     (2470, 'Igarapé-Açu', 14),
     (2471, 'Igarapé-Miri', 14),
     (2472, 'Inhangapi', 14),
     (2473, 'Ipixuna do Pará', 14),
     (2474, 'Irituia', 14),
     (2475, 'Itaituba', 14),
     (2476, 'Itupiranga', 14),
     (2477, 'Jacareacanga', 14),
     (2478, 'Jacundá', 14),
     (2479, 'Juruti', 14),
     (2480, 'Limoeiro do Ajuru', 14),
     (2481, 'Mãe do Rio', 14),
     (2482, 'Magalhães Barata', 14),
     (2483, 'Marabá', 14),
     (2484, 'Maracanã', 14),
     (2485, 'Marapanim', 14),
     (2486, 'Marituba', 14),
     (2487, 'Medicilândia', 14),
     (2488, 'Melgaço', 14),
     (2489, 'Mocajuba', 14),
     (2490, 'Moju', 14),
     (2491, 'Monte Alegre', 14),
     (2492, 'Muaná', 14),
     (2493, 'Nova Esperança do Piriá', 14),
     (2494, 'Nova Ipixuna', 14),
     (2495, 'Nova Timboteua', 14),
     (2496, 'Novo Progresso', 14),
     (2497, 'Novo Repartimento', 14),
     (2498, 'Óbidos', 14),
     (2499, 'Oeiras do Pará', 14),
     (2500, 'Oriximiná', 14),
     (2501, 'Ourém', 14),
     (2502, 'Ourilândia do Norte', 14),
     (2503, 'Pacajá', 14),
     (2504, 'Palestina do Pará', 14),
     (2505, 'Paragominas', 14),
     (2506, 'Parauapebas', 14),
     (2507, 'Pau dArco', 14),
     (2508, 'Peixe-Boi', 14),
     (2509, 'Piçarra', 14),
     (2510, 'Placas', 14),
     (2511, 'Ponta de Pedras', 14),
     (2512, 'Portel', 14),
     (2513, 'Porto de Moz', 14),
     (2514, 'Prainha', 14),
     (2515, 'Primavera', 14),
     (2516, 'Quatipuru', 14),
     (2517, 'Redenção', 14),
     (2518, 'Rio Maria', 14),
     (2519, 'Rondon do Pará', 14),
     (2520, 'Rurópolis', 14),
     (2521, 'Salinópolis', 14),
     (2522, 'Salvaterra', 14),
     (2523, 'Santa Bárbara do Pará', 14),
     (2524, 'Santa Cruz do Arari', 14),
     (2525, 'Santa Isabel do Pará', 14),
     (2526, 'Santa Luzia do Pará', 14),
     (2527, 'Santa Maria das Barreiras', 14),
     (2528, 'Santa Maria do Pará', 14),
     (2529, 'Santana do Araguaia', 14),
     (2530, 'Santarém', 14),
     (2531, 'Santarém Novo', 14),
     (2532, 'Santo Antônio do Tauá', 14),
     (2533, 'São Caetano de Odivelas', 14),
     (2534, 'São Domingos do Araguaia', 14),
     (2535, 'São Domingos do Capim', 14),
     (2536, 'São Félix do Xingu', 14),
     (2537, 'São Francisco do Pará', 14),
     (2538, 'São Geraldo do Araguaia', 14),
     (2539, 'São João da Ponta', 14),
     (2540, 'São João de Pirabas', 14),
     (2541, 'São João do Araguaia', 14),
     (2542, 'São Miguel do Guamá', 14),
     (2543, 'São Sebastião da Boa Vista', 14),
     (2544, 'Sapucaia', 14),
     (2545, 'Senador José Porfírio', 14),
     (2546, 'Soure', 14),
     (2547, 'Tailândia', 14),
     (2548, 'Terra Alta', 14),
     (2549, 'Terra Santa', 14),
     (2550, 'Tomé-Açu', 14),
     (2551, 'Tracuateua', 14),
     (2552, 'Trairão', 14),
     (2553, 'Tucumã', 14),
     (2554, 'Tucuruí', 14),
     (2555, 'Ulianópolis', 14),
     (2556, 'Uruará', 14),
     (2557, 'Vigia', 14),
     (2558, 'Viseu', 14),
     (2559, 'Vitória do Xingu', 14),
     (2560, 'Xinguara', 14),
     (2561, 'Água Branca', 15),
     (2562, 'Aguiar', 15),
     (2563, 'Alagoa Grande', 15),
     (2564, 'Alagoa Nova', 15),
     (2565, 'Alagoinha', 15),
     (2566, 'Alcantil', 15),
     (2567, 'Algodão de Jandaíra', 15),
     (2568, 'Alhandra', 15),
     (2569, 'Amparo', 15),
     (2570, 'Aparecida', 15),
     (2571, 'Araçagi', 15),
     (2572, 'Arara', 15),
     (2573, 'Araruna', 15),
     (2574, 'Areia', 15),
     (2575, 'Areia de Baraúnas', 15),
     (2576, 'Areial', 15),
     (2577, 'Aroeiras', 15),
     (2578, 'Assunção', 15),
     (2579, 'Baía da Traição', 15),
     (2580, 'Bananeiras', 15),
     (2581, 'Baraúna', 15),
     (2582, 'Barra de Santa Rosa', 15),
     (2583, 'Barra de Santana', 15),
     (2584, 'Barra de São Miguel', 15),
     (2585, 'Bayeux', 15),
     (2586, 'Belém', 15),
     (2587, 'Belém do Brejo do Cruz', 15),
     (2588, 'Bernardino Batista', 15),
     (2589, 'Boa Ventura', 15),
     (2590, 'Boa Vista', 15),
     (2591, 'Bom Jesus', 15),
     (2592, 'Bom Sucesso', 15),
     (2593, 'Bonito de Santa Fé', 15),
     (2594, 'Boqueirão', 15),
     (2595, 'Borborema', 15),
     (2596, 'Brejo do Cruz', 15),
     (2597, 'Brejo dos Santos', 15),
     (2598, 'Caaporã', 15),
     (2599, 'Cabaceiras', 15),
     (2600, 'Cabedelo', 15),
     (2601, 'Cachoeira dos Índios', 15),
     (2602, 'Cacimba de Areia', 15),
     (2603, 'Cacimba de Dentro', 15),
     (2604, 'Cacimbas', 15),
     (2605, 'Caiçara', 15),
     (2606, 'Cajazeiras', 15),
     (2607, 'Cajazeirinhas', 15),
     (2608, 'Caldas Brandão', 15),
     (2609, 'Camalaú', 15),
     (2610, 'Campina Grande', 15),
     (2611, 'Campo de Santana', 15),
     (2612, 'Capim', 15),
     (2613, 'Caraúbas', 15),
     (2614, 'Carrapateira', 15),
     (2615, 'Casserengue', 15),
     (2616, 'Catingueira', 15),
     (2617, 'Catolé do Rocha', 15),
     (2618, 'Caturité', 15),
     (2619, 'Conceição', 15),
     (2620, 'Condado', 15),
     (2621, 'Conde', 15),
     (2622, 'Congo', 15),
     (2623, 'Coremas', 15),
     (2624, 'Coxixola', 15),
     (2625, 'Cruz do Espírito Santo', 15),
     (2626, 'Cubati', 15),
     (2627, 'Cuité', 15),
     (2628, 'Cuité de Mamanguape', 15),
     (2629, 'Cuitegi', 15),
     (2630, 'Curral de Cima', 15),
     (2631, 'Curral Velho', 15),
     (2632, 'Damião', 15),
     (2633, 'Desterro', 15),
     (2634, 'Diamante', 15),
     (2635, 'Dona Inês', 15),
     (2636, 'Duas Estradas', 15),
     (2637, 'Emas', 15),
     (2638, 'Esperança', 15),
     (2639, 'Fagundes', 15),
     (2640, 'Frei Martinho', 15),
     (2641, 'Gado Bravo', 15),
     (2642, 'Guarabira', 15),
     (2643, 'Gurinhém', 15),
     (2644, 'Gurjão', 15),
     (2645, 'Ibiara', 15),
     (2646, 'Igaracy', 15),
     (2647, 'Imaculada', 15),
     (2648, 'Ingá', 15),
     (2649, 'Itabaiana', 15),
     (2650, 'Itaporanga', 15),
     (2651, 'Itapororoca', 15),
     (2652, 'Itatuba', 15),
     (2653, 'Jacaraú', 15),
     (2654, 'Jericó', 15),
     (2655, 'João Pessoa', 15),
     (2656, 'Juarez Távora', 15),
     (2657, 'Juazeirinho', 15),
     (2658, 'Junco do Seridó', 15),
     (2659, 'Juripiranga', 15),
     (2660, 'Juru', 15),
     (2661, 'Lagoa', 15),
     (2662, 'Lagoa de Dentro', 15),
     (2663, 'Lagoa Seca', 15),
     (2664, 'Lastro', 15),
     (2665, 'Livramento', 15),
     (2666, 'Logradouro', 15),
     (2667, 'Lucena', 15),
     (2668, 'Mãe dÁgua', 15),
     (2669, 'Malta', 15),
     (2670, 'Mamanguape', 15),
     (2671, 'Manaíra', 15),
     (2672, 'Marcação', 15),
     (2673, 'Mari', 15),
     (2674, 'Marizópolis', 15),
     (2675, 'Massaranduba', 15),
     (2676, 'Mataraca', 15),
     (2677, 'Matinhas', 15),
     (2678, 'Mato Grosso', 15),
     (2679, 'Maturéia', 15),
     (2680, 'Mogeiro', 15),
     (2681, 'Montadas', 15),
     (2682, 'Monte Horebe', 15),
     (2683, 'Monteiro', 15),
     (2684, 'Mulungu', 15),
     (2685, 'Natuba', 15),
     (2686, 'Nazarezinho', 15),
     (2687, 'Nova Floresta', 15),
     (2688, 'Nova Olinda', 15),
     (2689, 'Nova Palmeira', 15),
     (2690, 'Olho dÁgua', 15),
     (2691, 'Olivedos', 15),
     (2692, 'Ouro Velho', 15),
     (2693, 'Parari', 15),
     (2694, 'Passagem', 15),
     (2695, 'Patos', 15),
     (2696, 'Paulista', 15),
     (2697, 'Pedra Branca', 15),
     (2698, 'Pedra Lavrada', 15),
     (2699, 'Pedras de Fogo', 15),
     (2700, 'Pedro Régis', 15),
     (2701, 'Piancó', 15),
     (2702, 'Picuí', 15),
     (2703, 'Pilar', 15),
     (2704, 'Pilões', 15),
     (2705, 'Pilõezinhos', 15),
     (2706, 'Pirpirituba', 15),
     (2707, 'Pitimbu', 15),
     (2708, 'Pocinhos', 15),
     (2709, 'Poço Dantas', 15),
     (2710, 'Poço de José de Moura', 15),
     (2711, 'Pombal', 15),
     (2712, 'Prata', 15),
     (2713, 'Princesa Isabel', 15),
     (2714, 'Puxinanã', 15),
     (2715, 'Queimadas', 15),
     (2716, 'Quixabá', 15),
     (2717, 'Remígio', 15),
     (2718, 'Riachão', 15),
     (2719, 'Riachão do Bacamarte', 15),
     (2720, 'Riachão do Poço', 15),
     (2721, 'Riacho de Santo Antônio', 15),
     (2722, 'Riacho dos Cavalos', 15),
     (2723, 'Rio Tinto', 15),
     (2724, 'Salgadinho', 15),
     (2725, 'Salgado de São Félix', 15),
     (2726, 'Santa Cecília', 15),
     (2727, 'Santa Cruz', 15),
     (2728, 'Santa Helena', 15),
     (2729, 'Santa Inês', 15),
     (2730, 'Santa Luzia', 15),
     (2731, 'Santa Rita', 15),
     (2732, 'Santa Teresinha', 15),
     (2733, 'Santana de Mangueira', 15),
     (2734, 'Santana dos Garrotes', 15),
     (2735, 'Santarém', 15),
     (2736, 'Santo André', 15),
     (2737, 'São Bentinho', 15),
     (2738, 'São Bento', 15),
     (2739, 'São Domingos de Pombal', 15),
     (2740, 'São Domingos do Cariri', 15),
     (2741, 'São Francisco', 15),
     (2742, 'São João do Cariri', 15),
     (2743, 'São João do Rio do Peixe', 15),
     (2744, 'São João do Tigre', 15),
     (2745, 'São José da Lagoa Tapada', 15),
     (2746, 'São José de Caiana', 15),
     (2747, 'São José de Espinharas', 15),
     (2748, 'São José de Piranhas', 15),
     (2749, 'São José de Princesa', 15),
     (2750, 'São José do Bonfim', 15),
     (2751, 'São José do Brejo do Cruz', 15),
     (2752, 'São José do Sabugi', 15),
     (2753, 'São José dos Cordeiros', 15),
     (2754, 'São José dos Ramos', 15),
     (2755, 'São Mamede', 15),
     (2756, 'São Miguel de Taipu', 15),
     (2757, 'São Sebastião de Lagoa de Roça', 15),
     (2758, 'São Sebastião do Umbuzeiro', 15),
     (2759, 'Sapé', 15),
     (2760, 'Seridó', 15),
     (2761, 'Serra Branca', 15),
     (2762, 'Serra da Raiz', 15),
     (2763, 'Serra Grande', 15),
     (2764, 'Serra Redonda', 15),
     (2765, 'Serraria', 15),
     (2766, 'Sertãozinho', 15),
     (2767, 'Sobrado', 15),
     (2768, 'Solânea', 15),
     (2769, 'Soledade', 15),
     (2770, 'Sossêgo', 15),
     (2771, 'Sousa', 15),
     (2772, 'Sumé', 15),
     (2773, 'Taperoá', 15),
     (2774, 'Tavares', 15),
     (2775, 'Teixeira', 15),
     (2776, 'Tenório', 15),
     (2777, 'Triunfo', 15),
     (2778, 'Uiraúna', 15),
     (2779, 'Umbuzeiro', 15),
     (2780, 'Várzea', 15),
     (2781, 'Vieirópolis', 15),
     (2782, 'Vista Serrana', 15),
     (2783, 'Zabelê', 15),
     (2784, 'Abatiá', 18),
     (2785, 'Adrianópolis', 18),
     (2786, 'Agudos do Sul', 18),
     (2787, 'Almirante Tamandaré', 18),
     (2788, 'Altamira do Paraná', 18),
     (2789, 'Alto Paraíso', 18),
     (2790, 'Alto Paraná', 18),
     (2791, 'Alto Piquiri', 18),
     (2792, 'Altônia', 18),
     (2793, 'Alvorada do Sul', 18),
     (2794, 'Amaporã', 18),
     (2795, 'Ampére', 18),
     (2796, 'Anahy', 18),
     (2797, 'Andirá', 18),
     (2798, 'Ângulo', 18),
     (2799, 'Antonina', 18),
     (2800, 'Antônio Olinto', 18),
     (2801, 'Apucarana', 18),
     (2802, 'Arapongas', 18),
     (2803, 'Arapoti', 18),
     (2804, 'Arapuã', 18),
     (2805, 'Araruna', 18),
     (2806, 'Araucária', 18),
     (2807, 'Ariranha do Ivaí', 18),
     (2808, 'Assaí', 18),
     (2809, 'Assis Chateaubriand', 18),
     (2810, 'Astorga', 18),
     (2811, 'Atalaia', 18),
     (2812, 'Balsa Nova', 18),
     (2813, 'Bandeirantes', 18),
     (2814, 'Barbosa Ferraz', 18),
     (2815, 'Barra do Jacaré', 18),
     (2816, 'Barracão', 18),
     (2817, 'Bela Vista da Caroba', 18),
     (2818, 'Bela Vista do Paraíso', 18),
     (2819, 'Bituruna', 18),
     (2820, 'Boa Esperança', 18),
     (2821, 'Boa Esperança do Iguaçu', 18),
     (2822, 'Boa Ventura de São Roque', 18),
     (2823, 'Boa Vista da Aparecida', 18),
     (2824, 'Bocaiúva do Sul', 18),
     (2825, 'Bom Jesus do Sul', 18),
     (2826, 'Bom Sucesso', 18),
     (2827, 'Bom Sucesso do Sul', 18),
     (2828, 'Borrazópolis', 18),
     (2829, 'Braganey', 18),
     (2830, 'Brasilândia do Sul', 18),
     (2831, 'Cafeara', 18),
     (2832, 'Cafelândia', 18),
     (2833, 'Cafezal do Sul', 18),
     (2834, 'Califórnia', 18),
     (2835, 'Cambará', 18),
     (2836, 'Cambé', 18),
     (2837, 'Cambira', 18),
     (2838, 'Campina da Lagoa', 18),
     (2839, 'Campina do Simão', 18),
     (2840, 'Campina Grande do Sul', 18),
     (2841, 'Campo Bonito', 18),
     (2842, 'Campo do Tenente', 18),
     (2843, 'Campo Largo', 18),
     (2844, 'Campo Magro', 18),
     (2845, 'Campo Mourão', 18),
     (2846, 'Cândido de Abreu', 18),
     (2847, 'Candói', 18),
     (2848, 'Cantagalo', 18),
     (2849, 'Capanema', 18),
     (2850, 'Capitão Leônidas Marques', 18),
     (2851, 'Carambeí', 18),
     (2852, 'Carlópolis', 18),
     (2853, 'Cascavel', 18),
     (2854, 'Castro', 18),
     (2855, 'Catanduvas', 18),
     (2856, 'Centenário do Sul', 18),
     (2857, 'Cerro Azul', 18),
     (2858, 'Céu Azul', 18),
     (2859, 'Chopinzinho', 18),
     (2860, 'Cianorte', 18),
     (2861, 'Cidade Gaúcha', 18),
     (2862, 'Clevelândia', 18),
     (2863, 'Colombo', 18),
     (2864, 'Colorado', 18),
     (2865, 'Congonhinhas', 18),
     (2866, 'Conselheiro Mairinck', 18),
     (2867, 'Contenda', 18),
     (2868, 'Corbélia', 18),
     (2869, 'Cornélio Procópio', 18),
     (2870, 'Coronel Domingos Soares', 18),
     (2871, 'Coronel Vivida', 18),
     (2872, 'Corumbataí do Sul', 18),
     (2873, 'Cruz Machado', 18),
     (2874, 'Cruzeiro do Iguaçu', 18),
     (2875, 'Cruzeiro do Oeste', 18),
     (2876, 'Cruzeiro do Sul', 18),
     (2877, 'Cruzmaltina', 18),
     (2878, 'Curitiba', 18),
     (2879, 'Curiúva', 18),
     (2880, 'Diamante dOeste', 18),
     (2881, 'Diamante do Norte', 18),
     (2882, 'Diamante do Sul', 18),
     (2883, 'Dois Vizinhos', 18),
     (2884, 'Douradina', 18),
     (2885, 'Doutor Camargo', 18),
     (2886, 'Doutor Ulysses', 18),
     (2887, 'Enéas Marques', 18),
     (2888, 'Engenheiro Beltrão', 18),
     (2889, 'Entre Rios do Oeste', 18),
     (2890, 'Esperança Nova', 18),
     (2891, 'Espigão Alto do Iguaçu', 18),
     (2892, 'Farol', 18),
     (2893, 'Faxinal', 18),
     (2894, 'Fazenda Rio Grande', 18),
     (2895, 'Fênix', 18),
     (2896, 'Fernandes Pinheiro', 18),
     (2897, 'Figueira', 18),
     (2898, 'Flor da Serra do Sul', 18),
     (2899, 'Floraí', 18),
     (2900, 'Floresta', 18),
     (2901, 'Florestópolis', 18),
     (2902, 'Flórida', 18),
     (2903, 'Formosa do Oeste', 18),
     (2904, 'Foz do Iguaçu', 18),
     (2905, 'Foz do Jordão', 18),
     (2906, 'Francisco Alves', 18),
     (2907, 'Francisco Beltrão', 18),
     (2908, 'General Carneiro', 18),
     (2909, 'Godoy Moreira', 18),
     (2910, 'Goioerê', 18),
     (2911, 'Goioxim', 18),
     (2912, 'Grandes Rios', 18),
     (2913, 'Guaíra', 18),
     (2914, 'Guairaçá', 18),
     (2915, 'Guamiranga', 18),
     (2916, 'Guapirama', 18),
     (2917, 'Guaporema', 18),
     (2918, 'Guaraci', 18),
     (2919, 'Guaraniaçu', 18),
     (2920, 'Guarapuava', 18),
     (2921, 'Guaraqueçaba', 18),
     (2922, 'Guaratuba', 18),
     (2923, 'Honório Serpa', 18),
     (2924, 'Ibaiti', 18),
     (2925, 'Ibema', 18),
     (2926, 'Ibiporã', 18),
     (2927, 'Icaraíma', 18),
     (2928, 'Iguaraçu', 18),
     (2929, 'Iguatu', 18),
     (2930, 'Imbaú', 18),
     (2931, 'Imbituva', 18),
     (2932, 'Inácio Martins', 18),
     (2933, 'Inajá', 18),
     (2934, 'Indianópolis', 18),
     (2935, 'Ipiranga', 18),
     (2936, 'Iporã', 18),
     (2937, 'Iracema do Oeste', 18),
     (2938, 'Irati', 18),
     (2939, 'Iretama', 18),
     (2940, 'Itaguajé', 18),
     (2941, 'Itaipulândia', 18),
     (2942, 'Itambaracá', 18),
     (2943, 'Itambé', 18),
     (2944, 'Itapejara dOeste', 18),
     (2945, 'Itaperuçu', 18),
     (2946, 'Itaúna do Sul', 18),
     (2947, 'Ivaí', 18),
     (2948, 'Ivaiporã', 18),
     (2949, 'Ivaté', 18),
     (2950, 'Ivatuba', 18),
     (2951, 'Jaboti', 18),
     (2952, 'Jacarezinho', 18),
     (2953, 'Jaguapitã', 18),
     (2954, 'Jaguariaíva', 18),
     (2955, 'Jandaia do Sul', 18),
     (2956, 'Janiópolis', 18),
     (2957, 'Japira', 18),
     (2958, 'Japurá', 18),
     (2959, 'Jardim Alegre', 18),
     (2960, 'Jardim Olinda', 18),
     (2961, 'Jataizinho', 18),
     (2962, 'Jesuítas', 18),
     (2963, 'Joaquim Távora', 18),
     (2964, 'Jundiaí do Sul', 18),
     (2965, 'Juranda', 18),
     (2966, 'Jussara', 18),
     (2967, 'Kaloré', 18),
     (2968, 'Lapa', 18),
     (2969, 'Laranjal', 18),
     (2970, 'Laranjeiras do Sul', 18),
     (2971, 'Leópolis', 18),
     (2972, 'Lidianópolis', 18),
     (2973, 'Lindoeste', 18),
     (2974, 'Loanda', 18),
     (2975, 'Lobato', 18),
     (2976, 'Londrina', 18),
     (2977, 'Luiziana', 18),
     (2978, 'Lunardelli', 18),
     (2979, 'Lupionópolis', 18),
     (2980, 'Mallet', 18),
     (2981, 'Mamborê', 18),
     (2982, 'Mandaguaçu', 18),
     (2983, 'Mandaguari', 18),
     (2984, 'Mandirituba', 18),
     (2985, 'Manfrinópolis', 18),
     (2986, 'Mangueirinha', 18),
     (2987, 'Manoel Ribas', 18),
     (2988, 'Marechal Cândido Rondon', 18),
     (2989, 'Maria Helena', 18),
     (2990, 'Marialva', 18),
     (2991, 'Marilândia do Sul', 18),
     (2992, 'Marilena', 18),
     (2993, 'Mariluz', 18),
     (2994, 'Maringá', 18),
     (2995, 'Mariópolis', 18),
     (2996, 'Maripá', 18),
     (2997, 'Marmeleiro', 18),
     (2998, 'Marquinho', 18),
     (2999, 'Marumbi', 18),
     (3000, 'Matelândia', 18),
     (3001, 'Matinhos', 18),
     (3002, 'Mato Rico', 18),
     (3003, 'Mauá da Serra', 18),
     (3004, 'Medianeira', 18),
     (3005, 'Mercedes', 18),
     (3006, 'Mirador', 18),
     (3007, 'Miraselva', 18),
     (3008, 'Missal', 18),
     (3009, 'Moreira Sales', 18),
     (3010, 'Morretes', 18),
     (3011, 'Munhoz de Melo', 18),
     (3012, 'Nossa Senhora das Graças', 18),
     (3013, 'Nova Aliança do Ivaí', 18),
     (3014, 'Nova América da Colina', 18),
     (3015, 'Nova Aurora', 18),
     (3016, 'Nova Cantu', 18),
     (3017, 'Nova Esperança', 18),
     (3018, 'Nova Esperança do Sudoeste', 18),
     (3019, 'Nova Fátima', 18),
     (3020, 'Nova Laranjeiras', 18),
     (3021, 'Nova Londrina', 18),
     (3022, 'Nova Olímpia', 18),
     (3023, 'Nova Prata do Iguaçu', 18),
     (3024, 'Nova Santa Bárbara', 18),
     (3025, 'Nova Santa Rosa', 18),
     (3026, 'Nova Tebas', 18),
     (3027, 'Novo Itacolomi', 18),
     (3028, 'Ortigueira', 18),
     (3029, 'Ourizona', 18),
     (3030, 'Ouro Verde do Oeste', 18),
     (3031, 'Paiçandu', 18),
     (3032, 'Palmas', 18),
     (3033, 'Palmeira', 18),
     (3034, 'Palmital', 18),
     (3035, 'Palotina', 18),
     (3036, 'Paraíso do Norte', 18),
     (3037, 'Paranacity', 18),
     (3038, 'Paranaguá', 18),
     (3039, 'Paranapoema', 18),
     (3040, 'Paranavaí', 18),
     (3041, 'Pato Bragado', 18),
     (3042, 'Pato Branco', 18),
     (3043, 'Paula Freitas', 18),
     (3044, 'Paulo Frontin', 18),
     (3045, 'Peabiru', 18),
     (3046, 'Perobal', 18),
     (3047, 'Pérola', 18),
     (3048, 'Pérola dOeste', 18),
     (3049, 'Piên', 18),
     (3050, 'Pinhais', 18),
     (3051, 'Pinhal de São Bento', 18),
     (3052, 'Pinhalão', 18),
     (3053, 'Pinhão', 18),
     (3054, 'Piraí do Sul', 18),
     (3055, 'Piraquara', 18),
     (3056, 'Pitanga', 18),
     (3057, 'Pitangueiras', 18),
     (3058, 'Planaltina do Paraná', 18),
     (3059, 'Planalto', 18),
     (3060, 'Ponta Grossa', 18),
     (3061, 'Pontal do Paraná', 18),
     (3062, 'Porecatu', 18),
     (3063, 'Porto Amazonas', 18),
     (3064, 'Porto Barreiro', 18),
     (3065, 'Porto Rico', 18),
     (3066, 'Porto Vitória', 18),
     (3067, 'Prado Ferreira', 18),
     (3068, 'Pranchita', 18),
     (3069, 'Presidente Castelo Branco', 18),
     (3070, 'Primeiro de Maio', 18),
     (3071, 'Prudentópolis', 18),
     (3072, 'Quarto Centenário', 18),
     (3073, 'Quatiguá', 18),
     (3074, 'Quatro Barras', 18),
     (3075, 'Quatro Pontes', 18),
     (3076, 'Quedas do Iguaçu', 18),
     (3077, 'Querência do Norte', 18),
     (3078, 'Quinta do Sol', 18),
     (3079, 'Quitandinha', 18),
     (3080, 'Ramilândia', 18),
     (3081, 'Rancho Alegre', 18),
     (3082, 'Rancho Alegre dOeste', 18),
     (3083, 'Realeza', 18),
     (3084, 'Rebouças', 18),
     (3085, 'Renascença', 18),
     (3086, 'Reserva', 18),
     (3087, 'Reserva do Iguaçu', 18),
     (3088, 'Ribeirão Claro', 18),
     (3089, 'Ribeirão do Pinhal', 18),
     (3090, 'Rio Azul', 18),
     (3091, 'Rio Bom', 18),
     (3092, 'Rio Bonito do Iguaçu', 18),
     (3093, 'Rio Branco do Ivaí', 18),
     (3094, 'Rio Branco do Sul', 18),
     (3095, 'Rio Negro', 18),
     (3096, 'Rolândia', 18),
     (3097, 'Roncador', 18),
     (3098, 'Rondon', 18),
     (3099, 'Rosário do Ivaí', 18),
     (3100, 'Sabáudia', 18),
     (3101, 'Salgado Filho', 18),
     (3102, 'Salto do Itararé', 18),
     (3103, 'Salto do Lontra', 18),
     (3104, 'Santa Amélia', 18),
     (3105, 'Santa Cecília do Pavão', 18),
     (3106, 'Santa Cruz de Monte Castelo', 18),
     (3107, 'Santa Fé', 18),
     (3108, 'Santa Helena', 18),
     (3109, 'Santa Inês', 18),
     (3110, 'Santa Isabel do Ivaí', 18),
     (3111, 'Santa Izabel do Oeste', 18),
     (3112, 'Santa Lúcia', 18),
     (3113, 'Santa Maria do Oeste', 18),
     (3114, 'Santa Mariana', 18),
     (3115, 'Santa Mônica', 18),
     (3116, 'Santa Tereza do Oeste', 18),
     (3117, 'Santa Terezinha de Itaipu', 18),
     (3118, 'Santana do Itararé', 18),
     (3119, 'Santo Antônio da Platina', 18),
     (3120, 'Santo Antônio do Caiuá', 18),
     (3121, 'Santo Antônio do Paraíso', 18),
     (3122, 'Santo Antônio do Sudoeste', 18),
     (3123, 'Santo Inácio', 18),
     (3124, 'São Carlos do Ivaí', 18),
     (3125, 'São Jerônimo da Serra', 18),
     (3126, 'São João', 18),
     (3127, 'São João do Caiuá', 18),
     (3128, 'São João do Ivaí', 18),
     (3129, 'São João do Triunfo', 18),
     (3130, 'São Jorge dOeste', 18),
     (3131, 'São Jorge do Ivaí', 18),
     (3132, 'São Jorge do Patrocínio', 18),
     (3133, 'São José da Boa Vista', 18),
     (3134, 'São José das Palmeiras', 18),
     (3135, 'São José dos Pinhais', 18),
     (3136, 'São Manoel do Paraná', 18),
     (3137, 'São Mateus do Sul', 18),
     (3138, 'São Miguel do Iguaçu', 18),
     (3139, 'São Pedro do Iguaçu', 18),
     (3140, 'São Pedro do Ivaí', 18),
     (3141, 'São Pedro do Paraná', 18),
     (3142, 'São Sebastião da Amoreira', 18),
     (3143, 'São Tomé', 18),
     (3144, 'Sapopema', 18),
     (3145, 'Sarandi', 18),
     (3146, 'Saudade do Iguaçu', 18),
     (3147, 'Sengés', 18),
     (3148, 'Serranópolis do Iguaçu', 18),
     (3149, 'Sertaneja', 18),
     (3150, 'Sertanópolis', 18),
     (3151, 'Siqueira Campos', 18),
     (3152, 'Sulina', 18),
     (3153, 'Tamarana', 18),
     (3154, 'Tamboara', 18),
     (3155, 'Tapejara', 18),
     (3156, 'Tapira', 18),
     (3157, 'Teixeira Soares', 18),
     (3158, 'Telêmaco Borba', 18),
     (3159, 'Terra Boa', 18),
     (3160, 'Terra Rica', 18),
     (3161, 'Terra Roxa', 18),
     (3162, 'Tibagi', 18),
     (3163, 'Tijucas do Sul', 18),
     (3164, 'Toledo', 18),
     (3165, 'Tomazina', 18),
     (3166, 'Três Barras do Paraná', 18),
     (3167, 'Tunas do Paraná', 18),
     (3168, 'Tuneiras do Oeste', 18),
     (3169, 'Tupãssi', 18),
     (3170, 'Turvo', 18),
     (3171, 'Ubiratã', 18),
     (3172, 'Umuarama', 18),
     (3173, 'União da Vitória', 18),
     (3174, 'Uniflor', 18),
     (3175, 'Uraí', 18),
     (3176, 'Ventania', 18),
     (3177, 'Vera Cruz do Oeste', 18),
     (3178, 'Verê', 18),
     (3179, 'Virmond', 18),
     (3180, 'Vitorino', 18),
     (3181, 'Wenceslau Braz', 18),
     (3182, 'Xambrê', 18),
     (3183, 'Abreu e Lima', 16),
     (3184, 'Afogados da Ingazeira', 16),
     (3185, 'Afrânio', 16),
     (3186, 'Agrestina', 16),
     (3187, 'Água Preta', 16),
     (3188, 'Águas Belas', 16),
     (3189, 'Alagoinha', 16),
     (3190, 'Aliança', 16),
     (3191, 'Altinho', 16),
     (3192, 'Amaraji', 16),
     (3193, 'Angelim', 16),
     (3194, 'Araçoiaba', 16),
     (3195, 'Araripina', 16),
     (3196, 'Arcoverde', 16),
     (3197, 'Barra de Guabiraba', 16),
     (3198, 'Barreiros', 16),
     (3199, 'Belém de Maria', 16),
     (3200, 'Belém de São Francisco', 16),
     (3201, 'Belo Jardim', 16),
     (3202, 'Betânia', 16),
     (3203, 'Bezerros', 16),
     (3204, 'Bodocó', 16),
     (3205, 'Bom Conselho', 16),
     (3206, 'Bom Jardim', 16),
     (3207, 'Bonito', 16),
     (3208, 'Brejão', 16),
     (3209, 'Brejinho', 16),
     (3210, 'Brejo da Madre de Deus', 16),
     (3211, 'Buenos Aires', 16),
     (3212, 'Buíque', 16),
     (3213, 'Cabo de Santo Agostinho', 16),
     (3214, 'Cabrobó', 16),
     (3215, 'Cachoeirinha', 16),
     (3216, 'Caetés', 16),
     (3217, 'Calçado', 16),
     (3218, 'Calumbi', 16),
     (3219, 'Camaragibe', 16),
     (3220, 'Camocim de São Félix', 16),
     (3221, 'Camutanga', 16),
     (3222, 'Canhotinho', 16),
     (3223, 'Capoeiras', 16),
     (3224, 'Carnaíba', 16),
     (3225, 'Carnaubeira da Penha', 16),
     (3226, 'Carpina', 16),
     (3227, 'Caruaru', 16),
     (3228, 'Casinhas', 16),
     (3229, 'Catende', 16),
     (3230, 'Cedro', 16),
     (3231, 'Chã de Alegria', 16),
     (3232, 'Chã Grande', 16),
     (3233, 'Condado', 16),
     (3234, 'Correntes', 16),
     (3235, 'Cortês', 16),
     (3236, 'Cumaru', 16),
     (3237, 'Cupira', 16),
     (3238, 'Custódia', 16),
     (3239, 'Dormentes', 16),
     (3240, 'Escada', 16),
     (3241, 'Exu', 16),
     (3242, 'Feira Nova', 16),
     (3243, 'Fernando de Noronha', 16),
     (3244, 'Ferreiros', 16),
     (3245, 'Flores', 16),
     (3246, 'Floresta', 16),
     (3247, 'Frei Miguelinho', 16),
     (3248, 'Gameleira', 16),
     (3249, 'Garanhuns', 16),
     (3250, 'Glória do Goitá', 16),
     (3251, 'Goiana', 16),
     (3252, 'Granito', 16),
     (3253, 'Gravatá', 16),
     (3254, 'Iati', 16),
     (3255, 'Ibimirim', 16),
     (3256, 'Ibirajuba', 16),
     (3257, 'Igarassu', 16),
     (3258, 'Iguaraci', 16),
     (3259, 'Ilha de Itamaracá', 16),
     (3260, 'Inajá', 16),
     (3261, 'Ingazeira', 16),
     (3262, 'Ipojuca', 16),
     (3263, 'Ipubi', 16),
     (3264, 'Itacuruba', 16),
     (3265, 'Itaíba', 16),
     (3266, 'Itambé', 16),
     (3267, 'Itapetim', 16),
     (3268, 'Itapissuma', 16),
     (3269, 'Itaquitinga', 16),
     (3270, 'Jaboatão dos Guararapes', 16),
     (3271, 'Jaqueira', 16),
     (3272, 'Jataúba', 16),
     (3273, 'Jatobá', 16),
     (3274, 'João Alfredo', 16),
     (3275, 'Joaquim Nabuco', 16),
     (3276, 'Jucati', 16),
     (3277, 'Jupi', 16),
     (3278, 'Jurema', 16),
     (3279, 'Lagoa do Carro', 16),
     (3280, 'Lagoa do Itaenga', 16),
     (3281, 'Lagoa do Ouro', 16),
     (3282, 'Lagoa dos Gatos', 16),
     (3283, 'Lagoa Grande', 16),
     (3284, 'Lajedo', 16),
     (3285, 'Limoeiro', 16),
     (3286, 'Macaparana', 16),
     (3287, 'Machados', 16),
     (3288, 'Manari', 16),
     (3289, 'Maraial', 16),
     (3290, 'Mirandiba', 16),
     (3291, 'Moreilândia', 16),
     (3292, 'Moreno', 16),
     (3293, 'Nazaré da Mata', 16),
     (3294, 'Olinda', 16),
     (3295, 'Orobó', 16),
     (3296, 'Orocó', 16),
     (3297, 'Ouricuri', 16),
     (3298, 'Palmares', 16),
     (3299, 'Palmeirina', 16),
     (3300, 'Panelas', 16),
     (3301, 'Paranatama', 16),
     (3302, 'Parnamirim', 16),
     (3303, 'Passira', 16),
     (3304, 'Paudalho', 16),
     (3305, 'Paulista', 16),
     (3306, 'Pedra', 16),
     (3307, 'Pesqueira', 16),
     (3308, 'Petrolândia', 16),
     (3309, 'Petrolina', 16),
     (3310, 'Poção', 16),
     (3311, 'Pombos', 16),
     (3312, 'Primavera', 16),
     (3313, 'Quipapá', 16),
     (3314, 'Quixaba', 16),
     (3315, 'Recife', 16),
     (3316, 'Riacho das Almas', 16),
     (3317, 'Ribeirão', 16),
     (3318, 'Rio Formoso', 16),
     (3319, 'Sairé', 16),
     (3320, 'Salgadinho', 16),
     (3321, 'Salgueiro', 16),
     (3322, 'Saloá', 16),
     (3323, 'Sanharó', 16),
     (3324, 'Santa Cruz', 16),
     (3325, 'Santa Cruz da Baixa Verde', 16),
     (3326, 'Santa Cruz do Capibaribe', 16),
     (3327, 'Santa Filomena', 16),
     (3328, 'Santa Maria da Boa Vista', 16),
     (3329, 'Santa Maria do Cambucá', 16),
     (3330, 'Santa Terezinha', 16),
     (3331, 'São Benedito do Sul', 16),
     (3332, 'São Bento do Una', 16),
     (3333, 'São Caitano', 16),
     (3334, 'São João', 16),
     (3335, 'São Joaquim do Monte', 16),
     (3336, 'São José da Coroa Grande', 16),
     (3337, 'São José do Belmonte', 16),
     (3338, 'São José do Egito', 16),
     (3339, 'São Lourenço da Mata', 16),
     (3340, 'São Vicente Ferrer', 16),
     (3341, 'Serra Talhada', 16),
     (3342, 'Serrita', 16),
     (3343, 'Sertânia', 16),
     (3344, 'Sirinhaém', 16),
     (3345, 'Solidão', 16),
     (3346, 'Surubim', 16),
     (3347, 'Tabira', 16),
     (3348, 'Tacaimbó', 16),
     (3349, 'Tacaratu', 16),
     (3350, 'Tamandaré', 16),
     (3351, 'Taquaritinga do Norte', 16),
     (3352, 'Terezinha', 16),
     (3353, 'Terra Nova', 16),
     (3354, 'Timbaúba', 16),
     (3355, 'Toritama', 16),
     (3356, 'Tracunhaém', 16),
     (3357, 'Trindade', 16),
     (3358, 'Triunfo', 16),
     (3359, 'Tupanatinga', 16),
     (3360, 'Tuparetama', 16),
     (3361, 'Venturosa', 16),
     (3362, 'Verdejante', 16),
     (3363, 'Vertente do Lério', 16),
     (3364, 'Vertentes', 16),
     (3365, 'Vicência', 16),
     (3366, 'Vitória de Santo Antão', 16),
     (3367, 'Xexéu', 16),
     (3368, 'Acauã', 17),
     (3369, 'Agricolândia', 17),
     (3370, 'Água Branca', 17),
     (3371, 'Alagoinha do Piauí', 17),
     (3372, 'Alegrete do Piauí', 17),
     (3373, 'Alto Longá', 17),
     (3374, 'Altos', 17),
     (3375, 'Alvorada do Gurguéia', 17),
     (3376, 'Amarante', 17),
     (3377, 'Angical do Piauí', 17),
     (3378, 'Anísio de Abreu', 17),
     (3379, 'Antônio Almeida', 17),
     (3380, 'Aroazes', 17),
     (3381, 'Aroeiras do Itaim', 17),
     (3382, 'Arraial', 17),
     (3383, 'Assunção do Piauí', 17),
     (3384, 'Avelino Lopes', 17),
     (3385, 'Baixa Grande do Ribeiro', 17),
     (3386, 'Barra dAlcântara', 17),
     (3387, 'Barras', 17),
     (3388, 'Barreiras do Piauí', 17),
     (3389, 'Barro Duro', 17),
     (3390, 'Batalha', 17),
     (3391, 'Bela Vista do Piauí', 17),
     (3392, 'Belém do Piauí', 17),
     (3393, 'Beneditinos', 17),
     (3394, 'Bertolínia', 17),
     (3395, 'Betânia do Piauí', 17),
     (3396, 'Boa Hora', 17),
     (3397, 'Bocaina', 17),
     (3398, 'Bom Jesus', 17),
     (3399, 'Bom Princípio do Piauí', 17),
     (3400, 'Bonfim do Piauí', 17),
     (3401, 'Boqueirão do Piauí', 17),
     (3402, 'Brasileira', 17),
     (3403, 'Brejo do Piauí', 17),
     (3404, 'Buriti dos Lopes', 17),
     (3405, 'Buriti dos Montes', 17),
     (3406, 'Cabeceiras do Piauí', 17),
     (3407, 'Cajazeiras do Piauí', 17),
     (3408, 'Cajueiro da Praia', 17),
     (3409, 'Caldeirão Grande do Piauí', 17),
     (3410, 'Campinas do Piauí', 17),
     (3411, 'Campo Alegre do Fidalgo', 17),
     (3412, 'Campo Grande do Piauí', 17),
     (3413, 'Campo Largo do Piauí', 17),
     (3414, 'Campo Maior', 17),
     (3415, 'Canavieira', 17),
     (3416, 'Canto do Buriti', 17),
     (3417, 'Capitão de Campos', 17),
     (3418, 'Capitão Gervásio Oliveira', 17),
     (3419, 'Caracol', 17),
     (3420, 'Caraúbas do Piauí', 17),
     (3421, 'Caridade do Piauí', 17),
     (3422, 'Castelo do Piauí', 17),
     (3423, 'Caxingó', 17),
     (3424, 'Cocal', 17),
     (3425, 'Cocal de Telha', 17),
     (3426, 'Cocal dos Alves', 17),
     (3427, 'Coivaras', 17),
     (3428, 'Colônia do Gurguéia', 17),
     (3429, 'Colônia do Piauí', 17),
     (3430, 'Conceição do Canindé', 17),
     (3431, 'Coronel José Dias', 17),
     (3432, 'Corrente', 17),
     (3433, 'Cristalândia do Piauí', 17),
     (3434, 'Cristino Castro', 17),
     (3435, 'Curimatá', 17),
     (3436, 'Currais', 17),
     (3437, 'Curral Novo do Piauí', 17),
     (3438, 'Curralinhos', 17),
     (3439, 'Demerval Lobão', 17),
     (3440, 'Dirceu Arcoverde', 17),
     (3441, 'Dom Expedito Lopes', 17),
     (3442, 'Dom Inocêncio', 17),
     (3443, 'Domingos Mourão', 17),
     (3444, 'Elesbão Veloso', 17),
     (3445, 'Eliseu Martins', 17),
     (3446, 'Esperantina', 17),
     (3447, 'Fartura do Piauí', 17),
     (3448, 'Flores do Piauí', 17),
     (3449, 'Floresta do Piauí', 17),
     (3450, 'Floriano', 17),
     (3451, 'Francinópolis', 17),
     (3452, 'Francisco Ayres', 17),
     (3453, 'Francisco Macedo', 17),
     (3454, 'Francisco Santos', 17),
     (3455, 'Fronteiras', 17),
     (3456, 'Geminiano', 17),
     (3457, 'Gilbués', 17),
     (3458, 'Guadalupe', 17),
     (3459, 'Guaribas', 17),
     (3460, 'Hugo Napoleão', 17),
     (3461, 'Ilha Grande', 17),
     (3462, 'Inhuma', 17),
     (3463, 'Ipiranga do Piauí', 17),
     (3464, 'Isaías Coelho', 17),
     (3465, 'Itainópolis', 17),
     (3466, 'Itaueira', 17),
     (3467, 'Jacobina do Piauí', 17),
     (3468, 'Jaicós', 17),
     (3469, 'Jardim do Mulato', 17),
     (3470, 'Jatobá do Piauí', 17),
     (3471, 'Jerumenha', 17),
     (3472, 'João Costa', 17),
     (3473, 'Joaquim Pires', 17),
     (3474, 'Joca Marques', 17),
     (3475, 'José de Freitas', 17),
     (3476, 'Juazeiro do Piauí', 17),
     (3477, 'Júlio Borges', 17),
     (3478, 'Jurema', 17),
     (3479, 'Lagoa Alegre', 17),
     (3480, 'Lagoa de São Francisco', 17),
     (3481, 'Lagoa do Barro do Piauí', 17),
     (3482, 'Lagoa do Piauí', 17),
     (3483, 'Lagoa do Sítio', 17),
     (3484, 'Lagoinha do Piauí', 17),
     (3485, 'Landri Sales', 17),
     (3486, 'Luís Correia', 17),
     (3487, 'Luzilândia', 17),
     (3488, 'Madeiro', 17),
     (3489, 'Manoel Emídio', 17),
     (3490, 'Marcolândia', 17),
     (3491, 'Marcos Parente', 17),
     (3492, 'Massapê do Piauí', 17),
     (3493, 'Matias Olímpio', 17),
     (3494, 'Miguel Alves', 17),
     (3495, 'Miguel Leão', 17),
     (3496, 'Milton Brandão', 17),
     (3497, 'Monsenhor Gil', 17),
     (3498, 'Monsenhor Hipólito', 17),
     (3499, 'Monte Alegre do Piauí', 17),
     (3500, 'Morro Cabeça no Tempo', 17),
     (3501, 'Morro do Chapéu do Piauí', 17),
     (3502, 'Murici dos Portelas', 17),
     (3503, 'Nazaré do Piauí', 17),
     (3504, 'Nossa Senhora de Nazaré', 17),
     (3505, 'Nossa Senhora dos Remédios', 17),
     (3506, 'Nova Santa Rita', 17),
     (3507, 'Novo Oriente do Piauí', 17),
     (3508, 'Novo Santo Antônio', 17),
     (3509, 'Oeiras', 17),
     (3510, 'Olho dÁgua do Piauí', 17),
     (3511, 'Padre Marcos', 17),
     (3512, 'Paes Landim', 17),
     (3513, 'Pajeú do Piauí', 17),
     (3514, 'Palmeira do Piauí', 17),
     (3515, 'Palmeirais', 17),
     (3516, 'Paquetá', 17),
     (3517, 'Parnaguá', 17),
     (3518, 'Parnaíba', 17),
     (3519, 'Passagem Franca do Piauí', 17),
     (3520, 'Patos do Piauí', 17),
     (3521, 'Pau dArco do Piauí', 17),
     (3522, 'Paulistana', 17),
     (3523, 'Pavussu', 17),
     (3524, 'Pedro II', 17),
     (3525, 'Pedro Laurentino', 17),
     (3526, 'Picos', 17),
     (3527, 'Pimenteiras', 17),
     (3528, 'Pio IX', 17),
     (3529, 'Piracuruca', 17),
     (3530, 'Piripiri', 17),
     (3531, 'Porto', 17),
     (3532, 'Porto Alegre do Piauí', 17),
     (3533, 'Prata do Piauí', 17),
     (3534, 'Queimada Nova', 17),
     (3535, 'Redenção do Gurguéia', 17),
     (3536, 'Regeneração', 17),
     (3537, 'Riacho Frio', 17),
     (3538, 'Ribeira do Piauí', 17),
     (3539, 'Ribeiro Gonçalves', 17),
     (3540, 'Rio Grande do Piauí', 17),
     (3541, 'Santa Cruz do Piauí', 17),
     (3542, 'Santa Cruz dos Milagres', 17),
     (3543, 'Santa Filomena', 17),
     (3544, 'Santa Luz', 17),
     (3545, 'Santa Rosa do Piauí', 17),
     (3546, 'Santana do Piauí', 17),
     (3547, 'Santo Antônio de Lisboa', 17),
     (3548, 'Santo Antônio dos Milagres', 17),
     (3549, 'Santo Inácio do Piauí', 17),
     (3550, 'São Braz do Piauí', 17),
     (3551, 'São Félix do Piauí', 17),
     (3552, 'São Francisco de Assis do Piauí', 17),
     (3553, 'São Francisco do Piauí', 17),
     (3554, 'São Gonçalo do Gurguéia', 17),
     (3555, 'São Gonçalo do Piauí', 17),
     (3556, 'São João da Canabrava', 17),
     (3557, 'São João da Fronteira', 17),
     (3558, 'São João da Serra', 17),
     (3559, 'São João da Varjota', 17),
     (3560, 'São João do Arraial', 17),
     (3561, 'São João do Piauí', 17),
     (3562, 'São José do Divino', 17),
     (3563, 'São José do Peixe', 17),
     (3564, 'São José do Piauí', 17),
     (3565, 'São Julião', 17),
     (3566, 'São Lourenço do Piauí', 17),
     (3567, 'São Luis do Piauí', 17),
     (3568, 'São Miguel da Baixa Grande', 17),
     (3569, 'São Miguel do Fidalgo', 17),
     (3570, 'São Miguel do Tapuio', 17),
     (3571, 'São Pedro do Piauí', 17),
     (3572, 'São Raimundo Nonato', 17),
     (3573, 'Sebastião Barros', 17),
     (3574, 'Sebastião Leal', 17),
     (3575, 'Sigefredo Pacheco', 17),
     (3576, 'Simões', 17),
     (3577, 'Simplício Mendes', 17),
     (3578, 'Socorro do Piauí', 17),
     (3579, 'Sussuapara', 17),
     (3580, 'Tamboril do Piauí', 17),
     (3581, 'Tanque do Piauí', 17),
     (3582, 'Teresina', 17),
     (3583, 'União', 17),
     (3584, 'Uruçuí', 17),
     (3585, 'Valença do Piauí', 17),
     (3586, 'Várzea Branca', 17),
     (3587, 'Várzea Grande', 17),
     (3588, 'Vera Mendes', 17),
     (3589, 'Vila Nova do Piauí', 17),
     (3590, 'Wall Ferraz', 17),
     (3591, 'Angra dos Reis', 19),
     (3592, 'Aperibé', 19),
     (3593, 'Araruama', 19),
     (3594, 'Areal', 19),
     (3595, 'Armação dos Búzios', 19),
     (3596, 'Arraial do Cabo', 19),
     (3597, 'Barra do Piraí', 19),
     (3598, 'Barra Mansa', 19),
     (3599, 'Belford Roxo', 19),
     (3600, 'Bom Jardim', 19),
     (3601, 'Bom Jesus do Itabapoana', 19),
     (3602, 'Cabo Frio', 19),
     (3603, 'Cachoeiras de Macacu', 19),
     (3604, 'Cambuci', 19),
     (3605, 'Campos dos Goytacazes', 19),
     (3606, 'Cantagalo', 19),
     (3607, 'Carapebus', 19),
     (3608, 'Cardoso Moreira', 19),
     (3609, 'Carmo', 19),
     (3610, 'Casimiro de Abreu', 19),
     (3611, 'Comendador Levy Gasparian', 19),
     (3612, 'Conceição de Macabu', 19),
     (3613, 'Cordeiro', 19),
     (3614, 'Duas Barras', 19),
     (3615, 'Duque de Caxias', 19),
     (3616, 'Engenheiro Paulo de Frontin', 19),
     (3617, 'Guapimirim', 19),
     (3618, 'Iguaba Grande', 19),
     (3619, 'Itaboraí', 19),
     (3620, 'Itaguaí', 19),
     (3621, 'Italva', 19),
     (3622, 'Itaocara', 19),
     (3623, 'Itaperuna', 19),
     (3624, 'Itatiaia', 19),
     (3625, 'Japeri', 19),
     (3626, 'Laje do Muriaé', 19),
     (3627, 'Macaé', 19),
     (3628, 'Macuco', 19),
     (3629, 'Magé', 19),
     (3630, 'Mangaratiba', 19),
     (3631, 'Maricá', 19),
     (3632, 'Mendes', 19),
     (3633, 'Mesquita', 19),
     (3634, 'Miguel Pereira', 19),
     (3635, 'Miracema', 19),
     (3636, 'Natividade', 19),
     (3637, 'Nilópolis', 19),
     (3638, 'Niterói', 19),
     (3639, 'Nova Friburgo', 19),
     (3640, 'Nova Iguaçu', 19),
     (3641, 'Paracambi', 19),
     (3642, 'Paraíba do Sul', 19),
     (3643, 'Parati', 19),
     (3644, 'Paty do Alferes', 19),
     (3645, 'Petrópolis', 19),
     (3646, 'Pinheiral', 19),
     (3647, 'Piraí', 19),
     (3648, 'Porciúncula', 19),
     (3649, 'Porto Real', 19),
     (3650, 'Quatis', 19),
     (3651, 'Queimados', 19),
     (3652, 'Quissamã', 19),
     (3653, 'Resende', 19),
     (3654, 'Rio Bonito', 19),
     (3655, 'Rio Claro', 19),
     (3656, 'Rio das Flores', 19),
     (3657, 'Rio das Ostras', 19),
     (3658, 'Rio de Janeiro', 19),
     (3659, 'Santa Maria Madalena', 19),
     (3660, 'Santo Antônio de Pádua', 19),
     (3661, 'São Fidélis', 19),
     (3662, 'São Francisco de Itabapoana', 19),
     (3663, 'São Gonçalo', 19),
     (3664, 'São João da Barra', 19),
     (3665, 'São João de Meriti', 19),
     (3666, 'São José de Ubá', 19),
     (3667, 'São José do Vale do Rio Pret', 19),
     (3668, 'São Pedro da Aldeia', 19),
     (3669, 'São Sebastião do Alto', 19),
     (3670, 'Sapucaia', 19),
     (3671, 'Saquarema', 19),
     (3672, 'Seropédica', 19),
     (3673, 'Silva Jardim', 19),
     (3674, 'Sumidouro', 19),
     (3675, 'Tanguá', 19),
     (3676, 'Teresópolis', 19),
     (3677, 'Trajano de Morais', 19),
     (3678, 'Três Rios', 19),
     (3679, 'Valença', 19),
     (3680, 'Varre-Sai', 19),
     (3681, 'Vassouras', 19),
     (3682, 'Volta Redonda', 19),
     (3683, 'Acari', 20),
     (3684, 'Açu', 20),
     (3685, 'Afonso Bezerra', 20),
     (3686, 'Água Nova', 20),
     (3687, 'Alexandria', 20),
     (3688, 'Almino Afonso', 20),
     (3689, 'Alto do Rodrigues', 20),
     (3690, 'Angicos', 20),
     (3691, 'Antônio Martins', 20),
     (3692, 'Apodi', 20),
     (3693, 'Areia Branca', 20),
     (3694, 'Arês', 20),
     (3695, 'Augusto Severo', 20),
     (3696, 'Baía Formosa', 20),
     (3697, 'Baraúna', 20),
     (3698, 'Barcelona', 20),
     (3699, 'Bento Fernandes', 20),
     (3700, 'Bodó', 20),
     (3701, 'Bom Jesus', 20),
     (3702, 'Brejinho', 20),
     (3703, 'Caiçara do Norte', 20),
     (3704, 'Caiçara do Rio do Vento', 20),
     (3705, 'Caicó', 20),
     (3706, 'Campo Redondo', 20),
     (3707, 'Canguaretama', 20),
     (3708, 'Caraúbas', 20),
     (3709, 'Carnaúba dos Dantas', 20),
     (3710, 'Carnaubais', 20),
     (3711, 'Ceará-Mirim', 20),
     (3712, 'Cerro Corá', 20),
     (3713, 'Coronel Ezequiel', 20),
     (3714, 'Coronel João Pessoa', 20),
     (3715, 'Cruzeta', 20),
     (3716, 'Currais Novos', 20),
     (3717, 'Doutor Severiano', 20),
     (3718, 'Encanto', 20),
     (3719, 'Equador', 20),
     (3720, 'Espírito Santo', 20),
     (3721, 'Extremoz', 20),
     (3722, 'Felipe Guerra', 20),
     (3723, 'Fernando Pedroza', 20),
     (3724, 'Florânia', 20),
     (3725, 'Francisco Dantas', 20),
     (3726, 'Frutuoso Gomes', 20),
     (3727, 'Galinhos', 20),
     (3728, 'Goianinha', 20),
     (3729, 'Governador Dix-Sept Rosado', 20),
     (3730, 'Grossos', 20),
     (3731, 'Guamaré', 20),
     (3732, 'Ielmo Marinho', 20),
     (3733, 'Ipanguaçu', 20),
     (3734, 'Ipueira', 20),
     (3735, 'Itajá', 20),
     (3736, 'Itaú', 20),
     (3737, 'Jaçanã', 20),
     (3738, 'Jandaíra', 20),
     (3739, 'Janduís', 20),
     (3740, 'Januário Cicco', 20),
     (3741, 'Japi', 20),
     (3742, 'Jardim de Angicos', 20),
     (3743, 'Jardim de Piranhas', 20),
     (3744, 'Jardim do Seridó', 20),
     (3745, 'João Câmara', 20),
     (3746, 'João Dias', 20),
     (3747, 'José da Penha', 20),
     (3748, 'Jucurutu', 20),
     (3749, 'Jundiá', 20),
     (3750, 'Lagoa dAnta', 20),
     (3751, 'Lagoa de Pedras', 20),
     (3752, 'Lagoa de Velhos', 20),
     (3753, 'Lagoa Nova', 20),
     (3754, 'Lagoa Salgada', 20),
     (3755, 'Lajes', 20),
     (3756, 'Lajes Pintadas', 20),
     (3757, 'Lucrécia', 20),
     (3758, 'Luís Gomes', 20),
     (3759, 'Macaíba', 20),
     (3760, 'Macau', 20),
     (3761, 'Major Sales', 20),
     (3762, 'Marcelino Vieira', 20),
     (3763, 'Martins', 20),
     (3764, 'Maxaranguape', 20),
     (3765, 'Messias Targino', 20),
     (3766, 'Montanhas', 20),
     (3767, 'Monte Alegre', 20),
     (3768, 'Monte das Gameleiras', 20),
     (3769, 'Mossoró', 20),
     (3770, 'Natal', 20),
     (3771, 'Nísia Floresta', 20),
     (3772, 'Nova Cruz', 20),
     (3773, 'Olho-dÁgua do Borges', 20),
     (3774, 'Ouro Branco', 20),
     (3775, 'Paraná', 20),
     (3776, 'Paraú', 20),
     (3777, 'Parazinho', 20),
     (3778, 'Parelhas', 20),
     (3779, 'Parnamirim', 20),
     (3780, 'Passa e Fica', 20),
     (3781, 'Passagem', 20),
     (3782, 'Patu', 20),
     (3783, 'Pau dos Ferros', 20),
     (3784, 'Pedra Grande', 20),
     (3785, 'Pedra Preta', 20),
     (3786, 'Pedro Avelino', 20),
     (3787, 'Pedro Velho', 20),
     (3788, 'Pendências', 20),
     (3789, 'Pilões', 20),
     (3790, 'Poço Branco', 20),
     (3791, 'Portalegre', 20),
     (3792, 'Porto do Mangue', 20),
     (3793, 'Presidente Juscelino', 20),
     (3794, 'Pureza', 20),
     (3795, 'Rafael Fernandes', 20),
     (3796, 'Rafael Godeiro', 20),
     (3797, 'Riacho da Cruz', 20),
     (3798, 'Riacho de Santana', 20),
     (3799, 'Riachuelo', 20),
     (3800, 'Rio do Fogo', 20),
     (3801, 'Rodolfo Fernandes', 20),
     (3802, 'Ruy Barbosa', 20),
     (3803, 'Santa Cruz', 20),
     (3804, 'Santa Maria', 20),
     (3805, 'Santana do Matos', 20),
     (3806, 'Santana do Seridó', 20),
     (3807, 'Santo Antônio', 20),
     (3808, 'São Bento do Norte', 20),
     (3809, 'São Bento do Trairí', 20),
     (3810, 'São Fernando', 20),
     (3811, 'São Francisco do Oeste', 20),
     (3812, 'São Gonçalo do Amarante', 20),
     (3813, 'São João do Sabugi', 20),
     (3814, 'São José de Mipibu', 20),
     (3815, 'São José do Campestre', 20),
     (3816, 'São José do Seridó', 20),
     (3817, 'São Miguel', 20),
     (3818, 'São Miguel do Gostoso', 20),
     (3819, 'São Paulo do Potengi', 20),
     (3820, 'São Pedro', 20),
     (3821, 'São Rafael', 20),
     (3822, 'São Tomé', 20),
     (3823, 'São Vicente', 20),
     (3824, 'Senador Elói de Souza', 20),
     (3825, 'Senador Georgino Avelino', 20),
     (3826, 'Serra de São Bento', 20),
     (3827, 'Serra do Mel', 20),
     (3828, 'Serra Negra do Norte', 20),
     (3829, 'Serrinha', 20),
     (3830, 'Serrinha dos Pintos', 20),
     (3831, 'Severiano Melo', 20),
     (3832, 'Sítio Novo', 20),
     (3833, 'Taboleiro Grande', 20),
     (3834, 'Taipu', 20),
     (3835, 'Tangará', 20),
     (3836, 'Tenente Ananias', 20),
     (3837, 'Tenente Laurentino Cruz', 20),
     (3838, 'Tibau', 20),
     (3839, 'Tibau do Sul', 20),
     (3840, 'Timbaúba dos Batistas', 20),
     (3841, 'Touros', 20),
     (3842, 'Triunfo Potiguar', 20),
     (3843, 'Umarizal', 20),
     (3844, 'Upanema', 20),
     (3845, 'Várzea', 20),
     (3846, 'Venha-Ver', 20),
     (3847, 'Vera Cruz', 20),
     (3848, 'Viçosa', 20),
     (3849, 'Vila Flor', 20),
     (3850, 'Aceguá', 23),
     (3851, 'Água Santa', 23),
     (3852, 'Agudo', 23),
     (3853, 'Ajuricaba', 23),
     (3854, 'Alecrim', 23),
     (3855, 'Alegrete', 23),
     (3856, 'Alegria', 23),
     (3857, 'Almirante Tamandaré do Sul', 23),
     (3858, 'Alpestre', 23),
     (3859, 'Alto Alegre', 23),
     (3860, 'Alto Feliz', 23),
     (3861, 'Alvorada', 23),
     (3862, 'Amaral Ferrador', 23),
     (3863, 'Ametista do Sul', 23),
     (3864, 'André da Rocha', 23),
     (3865, 'Anta Gorda', 23),
     (3866, 'Antônio Prado', 23),
     (3867, 'Arambaré', 23),
     (3868, 'Araricá', 23),
     (3869, 'Aratiba', 23),
     (3870, 'Arroio do Meio', 23),
     (3871, 'Arroio do Padre', 23),
     (3872, 'Arroio do Sal', 23),
     (3873, 'Arroio do Tigre', 23),
     (3874, 'Arroio dos Ratos', 23),
     (3875, 'Arroio Grande', 23),
     (3876, 'Arvorezinha', 23),
     (3877, 'Augusto Pestana', 23),
     (3878, 'Áurea', 23),
     (3879, 'Bagé', 23),
     (3880, 'Balneário Pinhal', 23),
     (3881, 'Barão', 23),
     (3882, 'Barão de Cotegipe', 23),
     (3883, 'Barão do Triunfo', 23),
     (3884, 'Barra do Guarita', 23),
     (3885, 'Barra do Quaraí', 23),
     (3886, 'Barra do Ribeiro', 23),
     (3887, 'Barra do Rio Azul', 23),
     (3888, 'Barra Funda', 23),
     (3889, 'Barracão', 23),
     (3890, 'Barros Cassal', 23),
     (3891, 'Benjamin Constant do Sul', 23),
     (3892, 'Bento Gonçalves', 23),
     (3893, 'Boa Vista das Missões', 23),
     (3894, 'Boa Vista do Buricá', 23),
     (3895, 'Boa Vista do Cadeado', 23),
     (3896, 'Boa Vista do Incra', 23),
     (3897, 'Boa Vista do Sul', 23),
     (3898, 'Bom Jesus', 23),
     (3899, 'Bom Princípio', 23),
     (3900, 'Bom Progresso', 23),
     (3901, 'Bom Retiro do Sul', 23),
     (3902, 'Boqueirão do Leão', 23),
     (3903, 'Bossoroca', 23),
     (3904, 'Bozano', 23),
     (3905, 'Braga', 23),
     (3906, 'Brochier', 23),
     (3907, 'Butiá', 23),
     (3908, 'Caçapava do Sul', 23),
     (3909, 'Cacequi', 23),
     (3910, 'Cachoeira do Sul', 23),
     (3911, 'Cachoeirinha', 23),
     (3912, 'Cacique Doble', 23),
     (3913, 'Caibaté', 23),
     (3914, 'Caiçara', 23),
     (3915, 'Camaquã', 23),
     (3916, 'Camargo', 23),
     (3917, 'Cambará do Sul', 23),
     (3918, 'Campestre da Serra', 23),
     (3919, 'Campina das Missões', 23),
     (3920, 'Campinas do Sul', 23),
     (3921, 'Campo Bom', 23),
     (3922, 'Campo Novo', 23),
     (3923, 'Campos Borges', 23),
     (3924, 'Candelária', 23),
     (3925, 'Cândido Godói', 23),
     (3926, 'Candiota', 23),
     (3927, 'Canela', 23),
     (3928, 'Canguçu', 23),
     (3929, 'Canoas', 23),
     (3930, 'Canudos do Vale', 23),
     (3931, 'Capão Bonito do Sul', 23),
     (3932, 'Capão da Canoa', 23),
     (3933, 'Capão do Cipó', 23),
     (3934, 'Capão do Leão', 23),
     (3935, 'Capela de Santana', 23),
     (3936, 'Capitão', 23),
     (3937, 'Capivari do Sul', 23),
     (3938, 'Caraá', 23),
     (3939, 'Carazinho', 23),
     (3940, 'Carlos Barbosa', 23),
     (3941, 'Carlos Gomes', 23),
     (3942, 'Casca', 23),
     (3943, 'Caseiros', 23),
     (3944, 'Catuípe', 23),
     (3945, 'Caxias do Sul', 23),
     (3946, 'Centenário', 23),
     (3947, 'Cerrito', 23),
     (3948, 'Cerro Branco', 23),
     (3949, 'Cerro Grande', 23),
     (3950, 'Cerro Grande do Sul', 23),
     (3951, 'Cerro Largo', 23),
     (3952, 'Chapada', 23),
     (3953, 'Charqueadas', 23),
     (3954, 'Charrua', 23),
     (3955, 'Chiapeta', 23),
     (3956, 'Chuí', 23),
     (3957, 'Chuvisca', 23),
     (3958, 'Cidreira', 23),
     (3959, 'Ciríaco', 23),
     (3960, 'Colinas', 23),
     (3961, 'Colorado', 23),
     (3962, 'Condor', 23),
     (3963, 'Constantina', 23),
     (3964, 'Coqueiro Baixo', 23),
     (3965, 'Coqueiros do Sul', 23),
     (3966, 'Coronel Barros', 23),
     (3967, 'Coronel Bicaco', 23),
     (3968, 'Coronel Pilar', 23),
     (3969, 'Cotiporã', 23),
     (3970, 'Coxilha', 23),
     (3971, 'Crissiumal', 23),
     (3972, 'Cristal', 23),
     (3973, 'Cristal do Sul', 23),
     (3974, 'Cruz Alta', 23),
     (3975, 'Cruzaltense', 23),
     (3976, 'Cruzeiro do Sul', 23),
     (3977, 'David Canabarro', 23),
     (3978, 'Derrubadas', 23),
     (3979, 'Dezesseis de Novembro', 23),
     (3980, 'Dilermando de Aguiar', 23),
     (3981, 'Dois Irmãos', 23),
     (3982, 'Dois Irmãos das Missões', 23),
     (3983, 'Dois Lajeados', 23),
     (3984, 'Dom Feliciano', 23),
     (3985, 'Dom Pedrito', 23),
     (3986, 'Dom Pedro de Alcântara', 23),
     (3987, 'Dona Francisca', 23),
     (3988, 'Doutor Maurício Cardoso', 23),
     (3989, 'Doutor Ricardo', 23),
     (3990, 'Eldorado do Sul', 23),
     (3991, 'Encantado', 23),
     (3992, 'Encruzilhada do Sul', 23),
     (3993, 'Engenho Velho', 23),
     (3994, 'Entre Rios do Sul', 23),
     (3995, 'Entre-Ijuís', 23),
     (3996, 'Erebango', 23),
     (3997, 'Erechim', 23),
     (3998, 'Ernestina', 23),
     (3999, 'Erval Grande', 23),
     (4000, 'Erval Seco', 23),
     (4001, 'Esmeralda', 23),
     (4002, 'Esperança do Sul', 23),
     (4003, 'Espumoso', 23),
     (4004, 'Estação', 23),
     (4005, 'Estância Velha', 23),
     (4006, 'Esteio', 23),
     (4007, 'Estrela', 23),
     (4008, 'Estrela Velha', 23),
     (4009, 'Eugênio de Castro', 23),
     (4010, 'Fagundes Varela', 23),
     (4011, 'Farroupilha', 23),
     (4012, 'Faxinal do Soturno', 23),
     (4013, 'Faxinalzinho', 23),
     (4014, 'Fazenda Vilanova', 23),
     (4015, 'Feliz', 23),
     (4016, 'Flores da Cunha', 23),
     (4017, 'Floriano Peixoto', 23),
     (4018, 'Fontoura Xavier', 23),
     (4019, 'Formigueiro', 23),
     (4020, 'Forquetinha', 23),
     (4021, 'Fortaleza dos Valos', 23),
     (4022, 'Frederico Westphalen', 23),
     (4023, 'Garibaldi', 23),
     (4024, 'Garruchos', 23),
     (4025, 'Gaurama', 23),
     (4026, 'General Câmara', 23),
     (4027, 'Gentil', 23),
     (4028, 'Getúlio Vargas', 23),
     (4029, 'Giruá', 23),
     (4030, 'Glorinha', 23),
     (4031, 'Gramado', 23),
     (4032, 'Gramado dos Loureiros', 23),
     (4033, 'Gramado Xavier', 23),
     (4034, 'Gravataí', 23),
     (4035, 'Guabiju', 23),
     (4036, 'Guaíba', 23),
     (4037, 'Guaporé', 23),
     (4038, 'Guarani das Missões', 23),
     (4039, 'Harmonia', 23),
     (4040, 'Herval', 23),
     (4041, 'Herveiras', 23),
     (4042, 'Horizontina', 23),
     (4043, 'Hulha Negra', 23),
     (4044, 'Humaitá', 23),
     (4045, 'Ibarama', 23),
     (4046, 'Ibiaçá', 23),
     (4047, 'Ibiraiaras', 23),
     (4048, 'Ibirapuitã', 23),
     (4049, 'Ibirubá', 23),
     (4050, 'Igrejinha', 23),
     (4051, 'Ijuí', 23),
     (4052, 'Ilópolis', 23),
     (4053, 'Imbé', 23),
     (4054, 'Imigrante', 23),
     (4055, 'Independência', 23),
     (4056, 'Inhacorá', 23),
     (4057, 'Ipê', 23),
     (4058, 'Ipiranga do Sul', 23),
     (4059, 'Iraí', 23),
     (4060, 'Itaara', 23),
     (4061, 'Itacurubi', 23),
     (4062, 'Itapuca', 23),
     (4063, 'Itaqui', 23),
     (4064, 'Itati', 23),
     (4065, 'Itatiba do Sul', 23),
     (4066, 'Ivorá', 23),
     (4067, 'Ivoti', 23),
     (4068, 'Jaboticaba', 23),
     (4069, 'Jacuizinho', 23),
     (4070, 'Jacutinga', 23),
     (4071, 'Jaguarão', 23),
     (4072, 'Jaguari', 23),
     (4073, 'Jaquirana', 23),
     (4074, 'Jari', 23),
     (4075, 'Jóia', 23),
     (4076, 'Júlio de Castilhos', 23),
     (4077, 'Lagoa Bonita do Sul', 23),
     (4078, 'Lagoa dos Três Cantos', 23),
     (4079, 'Lagoa Vermelha', 23),
     (4080, 'Lagoão', 23),
     (4081, 'Lajeado', 23),
     (4082, 'Lajeado do Bugre', 23),
     (4083, 'Lavras do Sul', 23),
     (4084, 'Liberato Salzano', 23),
     (4085, 'Lindolfo Collor', 23),
     (4086, 'Linha Nova', 23),
     (4087, 'Maçambara', 23),
     (4088, 'Machadinho', 23),
     (4089, 'Mampituba', 23),
     (4090, 'Manoel Viana', 23),
     (4091, 'Maquiné', 23),
     (4092, 'Maratá', 23),
     (4093, 'Marau', 23),
     (4094, 'Marcelino Ramos', 23),
     (4095, 'Mariana Pimentel', 23),
     (4096, 'Mariano Moro', 23),
     (4097, 'Marques de Souza', 23),
     (4098, 'Mata', 23),
     (4099, 'Mato Castelhano', 23),
     (4100, 'Mato Leitão', 23),
     (4101, 'Mato Queimado', 23),
     (4102, 'Maximiliano de Almeida', 23),
     (4103, 'Minas do Leão', 23),
     (4104, 'Miraguaí', 23),
     (4105, 'Montauri', 23),
     (4106, 'Monte Alegre dos Campos', 23),
     (4107, 'Monte Belo do Sul', 23),
     (4108, 'Montenegro', 23),
     (4109, 'Mormaço', 23),
     (4110, 'Morrinhos do Sul', 23),
     (4111, 'Morro Redondo', 23),
     (4112, 'Morro Reuter', 23),
     (4113, 'Mostardas', 23),
     (4114, 'Muçum', 23),
     (4115, 'Muitos Capões', 23),
     (4116, 'Muliterno', 23),
     (4117, 'Não-Me-Toque', 23),
     (4118, 'Nicolau Vergueiro', 23),
     (4119, 'Nonoai', 23),
     (4120, 'Nova Alvorada', 23),
     (4121, 'Nova Araçá', 23),
     (4122, 'Nova Bassano', 23),
     (4123, 'Nova Boa Vista', 23),
     (4124, 'Nova Bréscia', 23),
     (4125, 'Nova Candelária', 23),
     (4126, 'Nova Esperança do Sul', 23),
     (4127, 'Nova Hartz', 23),
     (4128, 'Nova Pádua', 23),
     (4129, 'Nova Palma', 23),
     (4130, 'Nova Petrópolis', 23),
     (4131, 'Nova Prata', 23),
     (4132, 'Nova Ramada', 23),
     (4133, 'Nova Roma do Sul', 23),
     (4134, 'Nova Santa Rita', 23),
     (4135, 'Novo Barreiro', 23),
     (4136, 'Novo Cabrais', 23),
     (4137, 'Novo Hamburgo', 23),
     (4138, 'Novo Machado', 23),
     (4139, 'Novo Tiradentes', 23),
     (4140, 'Novo Xingu', 23),
     (4141, 'Osório', 23),
     (4142, 'Paim Filho', 23),
     (4143, 'Palmares do Sul', 23),
     (4144, 'Palmeira das Missões', 23),
     (4145, 'Palmitinho', 23),
     (4146, 'Panambi', 23),
     (4147, 'Pantano Grande', 23),
     (4148, 'Paraí', 23),
     (4149, 'Paraíso do Sul', 23),
     (4150, 'Pareci Novo', 23),
     (4151, 'Parobé', 23),
     (4152, 'Passa Sete', 23),
     (4153, 'Passo do Sobrado', 23),
     (4154, 'Passo Fundo', 23),
     (4155, 'Paulo Bento', 23),
     (4156, 'Paverama', 23),
     (4157, 'Pedras Altas', 23),
     (4158, 'Pedro Osório', 23),
     (4159, 'Pejuçara', 23),
     (4160, 'Pelotas', 23),
     (4161, 'Picada Café', 23),
     (4162, 'Pinhal', 23),
     (4163, 'Pinhal da Serra', 23),
     (4164, 'Pinhal Grande', 23),
     (4165, 'Pinheirinho do Vale', 23),
     (4166, 'Pinheiro Machado', 23),
     (4167, 'Pirapó', 23),
     (4168, 'Piratini', 23),
     (4169, 'Planalto', 23),
     (4170, 'Poço das Antas', 23),
     (4171, 'Pontão', 23),
     (4172, 'Ponte Preta', 23),
     (4173, 'Portão', 23),
     (4174, 'Porto Alegre', 23),
     (4175, 'Porto Lucena', 23),
     (4176, 'Porto Mauá', 23),
     (4177, 'Porto Vera Cruz', 23),
     (4178, 'Porto Xavier', 23),
     (4179, 'Pouso Novo', 23),
     (4180, 'Presidente Lucena', 23),
     (4181, 'Progresso', 23),
     (4182, 'Protásio Alves', 23),
     (4183, 'Putinga', 23),
     (4184, 'Quaraí', 23),
     (4185, 'Quatro Irmãos', 23),
     (4186, 'Quevedos', 23),
     (4187, 'Quinze de Novembro', 23),
     (4188, 'Redentora', 23),
     (4189, 'Relvado', 23),
     (4190, 'Restinga Seca', 23),
     (4191, 'Rio dos Índios', 23),
     (4192, 'Rio Grande', 23),
     (4193, 'Rio Pardo', 23),
     (4194, 'Riozinho', 23),
     (4195, 'Roca Sales', 23),
     (4196, 'Rodeio Bonito', 23),
     (4197, 'Rolador', 23),
     (4198, 'Rolante', 23),
     (4199, 'Ronda Alta', 23),
     (4200, 'Rondinha', 23),
     (4201, 'Roque Gonzales', 23),
     (4202, 'Rosário do Sul', 23),
     (4203, 'Sagrada Família', 23),
     (4204, 'Saldanha Marinho', 23),
     (4205, 'Salto do Jacuí', 23),
     (4206, 'Salvador das Missões', 23),
     (4207, 'Salvador do Sul', 23),
     (4208, 'Sananduva', 23),
     (4209, 'Santa Bárbara do Sul', 23),
     (4210, 'Santa Cecília do Sul', 23),
     (4211, 'Santa Clara do Sul', 23),
     (4212, 'Santa Cruz do Sul', 23),
     (4213, 'Santa Margarida do Sul', 23),
     (4214, 'Santa Maria', 23),
     (4215, 'Santa Maria do Herval', 23),
     (4216, 'Santa Rosa', 23),
     (4217, 'Santa Tereza', 23),
     (4218, 'Santa Vitória do Palmar', 23),
     (4219, 'Santana da Boa Vista', 23),
     (4220, 'Santana do Livramento', 23),
     (4221, 'Santiago', 23),
     (4222, 'Santo Ângelo', 23),
     (4223, 'Santo Antônio da Patrulha', 23),
     (4224, 'Santo Antônio das Missões', 23),
     (4225, 'Santo Antônio do Palma', 23),
     (4226, 'Santo Antônio do Planalto', 23),
     (4227, 'Santo Augusto', 23),
     (4228, 'Santo Cristo', 23),
     (4229, 'Santo Expedito do Sul', 23),
     (4230, 'São Borja', 23),
     (4231, 'São Domingos do Sul', 23),
     (4232, 'São Francisco de Assis', 23),
     (4233, 'São Francisco de Paula', 23),
     (4234, 'São Gabriel', 23),
     (4235, 'São Jerônimo', 23),
     (4236, 'São João da Urtiga', 23),
     (4237, 'São João do Polêsine', 23),
     (4238, 'São Jorge', 23),
     (4239, 'São José das Missões', 23),
     (4240, 'São José do Herval', 23),
     (4241, 'São José do Hortêncio', 23),
     (4242, 'São José do Inhacorá', 23),
     (4243, 'São José do Norte', 23),
     (4244, 'São José do Ouro', 23),
     (4245, 'São José do Sul', 23),
     (4246, 'São José dos Ausentes', 23),
     (4247, 'São Leopoldo', 23),
     (4248, 'São Lourenço do Sul', 23),
     (4249, 'São Luiz Gonzaga', 23),
     (4250, 'São Marcos', 23),
     (4251, 'São Martinho', 23),
     (4252, 'São Martinho da Serra', 23),
     (4253, 'São Miguel das Missões', 23),
     (4254, 'São Nicolau', 23),
     (4255, 'São Paulo das Missões', 23),
     (4256, 'São Pedro da Serra', 23),
     (4257, 'São Pedro das Missões', 23),
     (4258, 'São Pedro do Butiá', 23),
     (4259, 'São Pedro do Sul', 23),
     (4260, 'São Sebastião do Caí', 23),
     (4261, 'São Sepé', 23),
     (4262, 'São Valentim', 23),
     (4263, 'São Valentim do Sul', 23),
     (4264, 'São Valério do Sul', 23),
     (4265, 'São Vendelino', 23),
     (4266, 'São Vicente do Sul', 23),
     (4267, 'Sapiranga', 23),
     (4268, 'Sapucaia do Sul', 23),
     (4269, 'Sarandi', 23),
     (4270, 'Seberi', 23),
     (4271, 'Sede Nova', 23),
     (4272, 'Segredo', 23),
     (4273, 'Selbach', 23),
     (4274, 'Senador Salgado Filho', 23),
     (4275, 'Sentinela do Sul', 23),
     (4276, 'Serafina Corrêa', 23),
     (4277, 'Sério', 23),
     (4278, 'Sertão', 23),
     (4279, 'Sertão Santana', 23),
     (4280, 'Sete de Setembro', 23),
     (4281, 'Severiano de Almeida', 23),
     (4282, 'Silveira Martins', 23),
     (4283, 'Sinimbu', 23),
     (4284, 'Sobradinho', 23),
     (4285, 'Soledade', 23),
     (4286, 'Tabaí', 23),
     (4287, 'Tapejara', 23),
     (4288, 'Tapera', 23),
     (4289, 'Tapes', 23),
     (4290, 'Taquara', 23),
     (4291, 'Taquari', 23),
     (4292, 'Taquaruçu do Sul', 23),
     (4293, 'Tavares', 23),
     (4294, 'Tenente Portela', 23),
     (4295, 'Terra de Areia', 23),
     (4296, 'Teutônia', 23),
     (4297, 'Tio Hugo', 23),
     (4298, 'Tiradentes do Sul', 23),
     (4299, 'Toropi', 23),
     (4300, 'Torres', 23),
     (4301, 'Tramandaí', 23),
     (4302, 'Travesseiro', 23),
     (4303, 'Três Arroios', 23),
     (4304, 'Três Cachoeiras', 23),
     (4305, 'Três Coroas', 23),
     (4306, 'Três de Maio', 23),
     (4307, 'Três Forquilhas', 23),
     (4308, 'Três Palmeiras', 23),
     (4309, 'Três Passos', 23),
     (4310, 'Trindade do Sul', 23),
     (4311, 'Triunfo', 23),
     (4312, 'Tucunduva', 23),
     (4313, 'Tunas', 23),
     (4314, 'Tupanci do Sul', 23),
     (4315, 'Tupanciretã', 23),
     (4316, 'Tupandi', 23),
     (4317, 'Tuparendi', 23),
     (4318, 'Turuçu', 23),
     (4319, 'Ubiretama', 23),
     (4320, 'União da Serra', 23),
     (4321, 'Unistalda', 23),
     (4322, 'Uruguaiana', 23),
     (4323, 'Vacaria', 23),
     (4324, 'Vale do Sol', 23),
     (4325, 'Vale Real', 23),
     (4326, 'Vale Verde', 23),
     (4327, 'Vanini', 23),
     (4328, 'Venâncio Aires', 23),
     (4329, 'Vera Cruz', 23),
     (4330, 'Veranópolis', 23),
     (4331, 'Vespasiano Correa', 23),
     (4332, 'Viadutos', 23),
     (4333, 'Viamão', 23),
     (4334, 'Vicente Dutra', 23),
     (4335, 'Victor Graeff', 23),
     (4336, 'Vila Flores', 23),
     (4337, 'Vila Lângaro', 23),
     (4338, 'Vila Maria', 23),
     (4339, 'Vila Nova do Sul', 23),
     (4340, 'Vista Alegre', 23),
     (4341, 'Vista Alegre do Prata', 23),
     (4342, 'Vista Gaúcha', 23),
     (4343, 'Vitória das Missões', 23),
     (4344, 'Westfália', 23),
     (4345, 'Xangri-lá', 23),
     (4346, 'Alta Floresta dOeste', 21),
     (4347, 'Alto Alegre dos Parecis', 21),
     (4348, 'Alto Paraíso', 21),
     (4349, 'Alvorada dOeste', 21),
     (4350, 'Ariquemes', 21),
     (4351, 'Buritis', 21),
     (4352, 'Cabixi', 21),
     (4353, 'Cacaulândia', 21),
     (4354, 'Cacoal', 21),
     (4355, 'Campo Novo de Rondônia', 21),
     (4356, 'Candeias do Jamari', 21),
     (4357, 'Castanheiras', 21),
     (4358, 'Cerejeiras', 21),
     (4359, 'Chupinguaia', 21),
     (4360, 'Colorado do Oeste', 21),
     (4361, 'Corumbiara', 21),
     (4362, 'Costa Marques', 21),
     (4363, 'Cujubim', 21),
     (4364, 'Espigão dOeste', 21),
     (4365, 'Governador Jorge Teixeira', 21),
     (4366, 'Guajará-Mirim', 21),
     (4367, 'Itapuã do Oeste', 21),
     (4368, 'Jaru', 21),
     (4369, 'Ji-Paraná', 21),
     (4370, 'Machadinho dOeste', 21),
     (4371, 'Ministro Andreazza', 21),
     (4372, 'Mirante da Serra', 21),
     (4373, 'Monte Negro', 21),
     (4374, 'Nova Brasilândia dOeste', 21),
     (4375, 'Nova Mamoré', 21),
     (4376, 'Nova União', 21),
     (4377, 'Novo Horizonte do Oeste', 21),
     (4378, 'Ouro Preto do Oeste', 21),
     (4379, 'Parecis', 21),
     (4380, 'Pimenta Bueno', 21),
     (4381, 'Pimenteiras do Oeste', 21),
     (4382, 'Porto Velho', 21),
     (4383, 'Presidente Médici', 21),
     (4384, 'Primavera de Rondônia', 21),
     (4385, 'Rio Crespo', 21),
     (4386, 'Rolim de Moura', 21),
     (4387, 'Santa Luzia dOeste', 21),
     (4388, 'São Felipe dOeste', 21),
     (4389, 'São Francisco do Guaporé', 21),
     (4390, 'São Miguel do Guaporé', 21),
     (4391, 'Seringueiras', 21),
     (4392, 'Teixeirópolis', 21),
     (4393, 'Theobroma', 21),
     (4394, 'Urupá', 21),
     (4395, 'Vale do Anari', 21),
     (4396, 'Vale do Paraíso', 21),
     (4397, 'Vilhena', 21),
     (4398, 'Alto Alegre', 22),
     (4399, 'Amajari', 22),
     (4400, 'Boa Vista', 22),
     (4401, 'Bonfim', 22),
     (4402, 'Cantá', 22),
     (4403, 'Caracaraí', 22),
     (4404, 'Caroebe', 22),
     (4405, 'Iracema', 22),
     (4406, 'Mucajaí', 22),
     (4407, 'Normandia', 22),
     (4408, 'Pacaraima', 22),
     (4409, 'Rorainópolis', 22),
     (4410, 'São João da Baliza', 22),
     (4411, 'São Luiz', 22),
     (4412, 'Uiramutã', 22),
     (4413, 'Abdon Batista', 24),
     (4414, 'Abelardo Luz', 24),
     (4415, 'Agrolândia', 24),
     (4416, 'Agronômica', 24),
     (4417, 'Água Doce', 24),
     (4418, 'Águas de Chapecó', 24),
     (4419, 'Águas Frias', 24),
     (4420, 'Águas Mornas', 24),
     (4421, 'Alfredo Wagner', 24),
     (4422, 'Alto Bela Vista', 24),
     (4423, 'Anchieta', 24),
     (4424, 'Angelina', 24),
     (4425, 'Anita Garibaldi', 24),
     (4426, 'Anitápolis', 24),
     (4427, 'Antônio Carlos', 24),
     (4428, 'Apiúna', 24),
     (4429, 'Arabutã', 24),
     (4430, 'Araquari', 24),
     (4431, 'Araranguá', 24),
     (4432, 'Armazém', 24),
     (4433, 'Arroio Trinta', 24),
     (4434, 'Arvoredo', 24),
     (4435, 'Ascurra', 24),
     (4436, 'Atalanta', 24),
     (4437, 'Aurora', 24),
     (4438, 'Balneário Arroio do Silva', 24),
     (4439, 'Balneário Barra do Sul', 24),
     (4440, 'Balneário Camboriú', 24),
     (4441, 'Balneário Gaivota', 24),
     (4442, 'Bandeirante', 24),
     (4443, 'Barra Bonita', 24),
     (4444, 'Barra Velha', 24),
     (4445, 'Bela Vista do Toldo', 24),
     (4446, 'Belmonte', 24),
     (4447, 'Benedito Novo', 24),
     (4448, 'Biguaçu', 24),
     (4449, 'Blumenau', 24),
     (4450, 'Bocaina do Sul', 24),
     (4451, 'Bom Jardim da Serra', 24),
     (4452, 'Bom Jesus', 24),
     (4453, 'Bom Jesus do Oeste', 24),
     (4454, 'Bom Retiro', 24),
     (4455, 'Bombinhas', 24),
     (4456, 'Botuverá', 24),
     (4457, 'Braço do Norte', 24),
     (4458, 'Braço do Trombudo', 24),
     (4459, 'Brunópolis', 24),
     (4460, 'Brusque', 24),
     (4461, 'Caçador', 24),
     (4462, 'Caibi', 24),
     (4463, 'Calmon', 24),
     (4464, 'Camboriú', 24),
     (4465, 'Campo Alegre', 24),
     (4466, 'Campo Belo do Sul', 24),
     (4467, 'Campo Erê', 24),
     (4468, 'Campos Novos', 24),
     (4469, 'Canelinha', 24),
     (4470, 'Canoinhas', 24),
     (4471, 'Capão Alto', 24),
     (4472, 'Capinzal', 24),
     (4473, 'Capivari de Baixo', 24),
     (4474, 'Catanduvas', 24),
     (4475, 'Caxambu do Sul', 24),
     (4476, 'Celso Ramos', 24),
     (4477, 'Cerro Negro', 24),
     (4478, 'Chapadão do Lageado', 24),
     (4479, 'Chapecó', 24),
     (4480, 'Cocal do Sul', 24),
     (4481, 'Concórdia', 24),
     (4482, 'Cordilheira Alta', 24),
     (4483, 'Coronel Freitas', 24),
     (4484, 'Coronel Martins', 24),
     (4485, 'Correia Pinto', 24),
     (4486, 'Corupá', 24),
     (4487, 'Criciúma', 24),
     (4488, 'Cunha Porã', 24),
     (4489, 'Cunhataí', 24),
     (4490, 'Curitibanos', 24),
     (4491, 'Descanso', 24),
     (4492, 'Dionísio Cerqueira', 24),
     (4493, 'Dona Emma', 24),
     (4494, 'Doutor Pedrinho', 24),
     (4495, 'Entre Rios', 24),
     (4496, 'Ermo', 24),
     (4497, 'Erval Velho', 24),
     (4498, 'Faxinal dos Guedes', 24),
     (4499, 'Flor do Sertão', 24),
     (4500, 'Florianópolis', 24),
     (4501, 'Formosa do Sul', 24),
     (4502, 'Forquilhinha', 24),
     (4503, 'Fraiburgo', 24),
     (4504, 'Frei Rogério', 24),
     (4505, 'Galvão', 24),
     (4506, 'Garopaba', 24),
     (4507, 'Garuva', 24),
     (4508, 'Gaspar', 24),
     (4509, 'Governador Celso Ramos', 24),
     (4510, 'Grão Pará', 24),
     (4511, 'Gravatal', 24),
     (4512, 'Guabiruba', 24),
     (4513, 'Guaraciaba', 24),
     (4514, 'Guaramirim', 24),
     (4515, 'Guarujá do Sul', 24),
     (4516, 'Guatambú', 24),
     (4517, 'Herval dOeste', 24),
     (4518, 'Ibiam', 24),
     (4519, 'Ibicaré', 24),
     (4520, 'Ibirama', 24),
     (4521, 'Içara', 24),
     (4522, 'Ilhota', 24),
     (4523, 'Imaruí', 24),
     (4524, 'Imbituba', 24),
     (4525, 'Imbuia', 24),
     (4526, 'Indaial', 24),
     (4527, 'Iomerê', 24),
     (4528, 'Ipira', 24),
     (4529, 'Iporã do Oeste', 24),
     (4530, 'Ipuaçu', 24),
     (4531, 'Ipumirim', 24),
     (4532, 'Iraceminha', 24),
     (4533, 'Irani', 24),
     (4534, 'Irati', 24),
     (4535, 'Irineópolis', 24),
     (4536, 'Itá', 24),
     (4537, 'Itaiópolis', 24),
     (4538, 'Itajaí', 24),
     (4539, 'Itapema', 24),
     (4540, 'Itapiranga', 24),
     (4541, 'Itapoá', 24),
     (4542, 'Ituporanga', 24),
     (4543, 'Jaborá', 24),
     (4544, 'Jacinto Machado', 24),
     (4545, 'Jaguaruna', 24),
     (4546, 'Jaraguá do Sul', 24),
     (4547, 'Jardinópolis', 24),
     (4548, 'Joaçaba', 24),
     (4549, 'Joinville', 24),
     (4550, 'José Boiteux', 24),
     (4551, 'Jupiá', 24),
     (4552, 'Lacerdópolis', 24),
     (4553, 'Lages', 24),
     (4554, 'Laguna', 24),
     (4555, 'Lajeado Grande', 24),
     (4556, 'Laurentino', 24),
     (4557, 'Lauro Muller', 24),
     (4558, 'Lebon Régis', 24),
     (4559, 'Leoberto Leal', 24),
     (4560, 'Lindóia do Sul', 24),
     (4561, 'Lontras', 24),
     (4562, 'Luiz Alves', 24),
     (4563, 'Luzerna', 24),
     (4564, 'Macieira', 24),
     (4565, 'Mafra', 24),
     (4566, 'Major Gercino', 24),
     (4567, 'Major Vieira', 24),
     (4568, 'Maracajá', 24),
     (4569, 'Maravilha', 24),
     (4570, 'Marema', 24),
     (4571, 'Massaranduba', 24),
     (4572, 'Matos Costa', 24),
     (4573, 'Meleiro', 24),
     (4574, 'Mirim Doce', 24),
     (4575, 'Modelo', 24),
     (4576, 'Mondaí', 24),
     (4577, 'Monte Carlo', 24),
     (4578, 'Monte Castelo', 24),
     (4579, 'Morro da Fumaça', 24),
     (4580, 'Morro Grande', 24),
     (4581, 'Navegantes', 24),
     (4582, 'Nova Erechim', 24),
     (4583, 'Nova Itaberaba', 24),
     (4584, 'Nova Trento', 24),
     (4585, 'Nova Veneza', 24),
     (4586, 'Novo Horizonte', 24),
     (4587, 'Orleans', 24),
     (4588, 'Otacílio Costa', 24),
     (4589, 'Ouro', 24),
     (4590, 'Ouro Verde', 24),
     (4591, 'Paial', 24),
     (4592, 'Painel', 24),
     (4593, 'Palhoça', 24),
     (4594, 'Palma Sola', 24),
     (4595, 'Palmeira', 24),
     (4596, 'Palmitos', 24),
     (4597, 'Papanduva', 24),
     (4598, 'Paraíso', 24),
     (4599, 'Passo de Torres', 24),
     (4600, 'Passos Maia', 24),
     (4601, 'Paulo Lopes', 24),
     (4602, 'Pedras Grandes', 24),
     (4603, 'Penha', 24),
     (4604, 'Peritiba', 24),
     (4605, 'Petrolândia', 24),
     (4606, 'Piçarras', 24),
     (4607, 'Pinhalzinho', 24),
     (4608, 'Pinheiro Preto', 24),
     (4609, 'Piratuba', 24),
     (4610, 'Planalto Alegre', 24),
     (4611, 'Pomerode', 24),
     (4612, 'Ponte Alta', 24),
     (4613, 'Ponte Alta do Norte', 24),
     (4614, 'Ponte Serrada', 24),
     (4615, 'Porto Belo', 24),
     (4616, 'Porto União', 24),
     (4617, 'Pouso Redondo', 24),
     (4618, 'Praia Grande', 24),
     (4619, 'Presidente Castelo Branco', 24),
     (4620, 'Presidente Getúlio', 24),
     (4621, 'Presidente Nereu', 24),
     (4622, 'Princesa', 24),
     (4623, 'Quilombo', 24),
     (4624, 'Rancho Queimado', 24),
     (4625, 'Rio das Antas', 24),
     (4626, 'Rio do Campo', 24),
     (4627, 'Rio do Oeste', 24),
     (4628, 'Rio do Sul', 24),
     (4629, 'Rio dos Cedros', 24),
     (4630, 'Rio Fortuna', 24),
     (4631, 'Rio Negrinho', 24),
     (4632, 'Rio Rufino', 24),
     (4633, 'Riqueza', 24),
     (4634, 'Rodeio', 24),
     (4635, 'Romelândia', 24),
     (4636, 'Salete', 24),
     (4637, 'Saltinho', 24),
     (4638, 'Salto Veloso', 24),
     (4639, 'Sangão', 24),
     (4640, 'Santa Cecília', 24),
     (4641, 'Santa Helena', 24),
     (4642, 'Santa Rosa de Lima', 24),
     (4643, 'Santa Rosa do Sul', 24),
     (4644, 'Santa Terezinha', 24),
     (4645, 'Santa Terezinha do Progresso', 24),
     (4646, 'Santiago do Sul', 24),
     (4647, 'Santo Amaro da Imperatriz', 24),
     (4648, 'São Bento do Sul', 24),
     (4649, 'São Bernardino', 24),
     (4650, 'São Bonifácio', 24),
     (4651, 'São Carlos', 24),
     (4652, 'São Cristovão do Sul', 24),
     (4653, 'São Domingos', 24),
     (4654, 'São Francisco do Sul', 24),
     (4655, 'São João Batista', 24),
     (4656, 'São João do Itaperiú', 24),
     (4657, 'São João do Oeste', 24),
     (4658, 'São João do Sul', 24),
     (4659, 'São Joaquim', 24),
     (4660, 'São José', 24),
     (4661, 'São José do Cedro', 24),
     (4662, 'São José do Cerrito', 24),
     (4663, 'São Lourenço do Oeste', 24),
     (4664, 'São Ludgero', 24),
     (4665, 'São Martinho', 24),
     (4666, 'São Miguel da Boa Vista', 24),
     (4667, 'São Miguel do Oeste', 24),
     (4668, 'São Pedro de Alcântara', 24),
     (4669, 'Saudades', 24),
     (4670, 'Schroeder', 24),
     (4671, 'Seara', 24),
     (4672, 'Serra Alta', 24),
     (4673, 'Siderópolis', 24),
     (4674, 'Sombrio', 24),
     (4675, 'Sul Brasil', 24),
     (4676, 'Taió', 24),
     (4677, 'Tangará', 24),
     (4678, 'Tigrinhos', 24),
     (4679, 'Tijucas', 24),
     (4680, 'Timbé do Sul', 24),
     (4681, 'Timbó', 24),
     (4682, 'Timbó Grande', 24),
     (4683, 'Três Barras', 24),
     (4684, 'Treviso', 24),
     (4685, 'Treze de Maio', 24),
     (4686, 'Treze Tílias', 24),
     (4687, 'Trombudo Central', 24),
     (4688, 'Tubarão', 24),
     (4689, 'Tunápolis', 24),
     (4690, 'Turvo', 24),
     (4691, 'União do Oeste', 24),
     (4692, 'Urubici', 24),
     (4693, 'Urupema', 24),
     (4694, 'Urussanga', 24),
     (4695, 'Vargeão', 24),
     (4696, 'Vargem', 24),
     (4697, 'Vargem Bonita', 24),
     (4698, 'Vidal Ramos', 24),
     (4699, 'Videira', 24),
     (4700, 'Vitor Meireles', 24),
     (4701, 'Witmarsum', 24),
     (4702, 'Xanxerê', 24),
     (4703, 'Xavantina', 24),
     (4704, 'Xaxim', 24),
     (4705, 'Zortéa', 24),
     (4706, 'Adamantina', 26),
     (4707, 'Adolfo', 26),
     (4708, 'Aguaí', 26),
     (4709, 'Águas da Prata', 26),
     (4710, 'Águas de Lindóia', 26),
     (4711, 'Águas de Santa Bárbara', 26),
     (4712, 'Águas de São Pedro', 26),
     (4713, 'Agudos', 26),
     (4714, 'Alambari', 26),
     (4715, 'Alfredo Marcondes', 26),
     (4716, 'Altair', 26),
     (4717, 'Altinópolis', 26),
     (4718, 'Alto Alegre', 26),
     (4719, 'Alumínio', 26),
     (4720, 'Álvares Florence', 26),
     (4721, 'Álvares Machado', 26),
     (4722, 'Álvaro de Carvalho', 26),
     (4723, 'Alvinlândia', 26),
     (4724, 'Americana', 26),
     (4725, 'Américo Brasiliense', 26),
     (4726, 'Américo de Campos', 26),
     (4727, 'Amparo', 26),
     (4728, 'Analândia', 26),
     (4729, 'Andradina', 26),
     (4730, 'Angatuba', 26),
     (4731, 'Anhembi', 26),
     (4732, 'Anhumas', 26),
     (4733, 'Aparecida', 26),
     (4734, 'Aparecida dOeste', 26),
     (4735, 'Apiaí', 26),
     (4736, 'Araçariguama', 26),
     (4737, 'Araçatuba', 26),
     (4738, 'Araçoiaba da Serra', 26),
     (4739, 'Aramina', 26),
     (4740, 'Arandu', 26),
     (4741, 'Arapeí', 26),
     (4742, 'Araraquara', 26),
     (4743, 'Araras', 26),
     (4744, 'Arco-Íris', 26),
     (4745, 'Arealva', 26),
     (4746, 'Areias', 26),
     (4747, 'Areiópolis', 26),
     (4748, 'Ariranha', 26),
     (4749, 'Artur Nogueira', 26),
     (4750, 'Arujá', 26),
     (4751, 'Aspásia', 26),
     (4752, 'Assis', 26),
     (4753, 'Atibaia', 26),
     (4754, 'Auriflama', 26),
     (4755, 'Avaí', 26),
     (4756, 'Avanhandava', 26),
     (4757, 'Avaré', 26),
     (4758, 'Bady Bassitt', 26),
     (4759, 'Balbinos', 26),
     (4760, 'Bálsamo', 26),
     (4761, 'Bananal', 26),
     (4762, 'Barão de Antonina', 26),
     (4763, 'Barbosa', 26),
     (4764, 'Bariri', 26),
     (4765, 'Barra Bonita', 26),
     (4766, 'Barra do Chapéu', 26),
     (4767, 'Barra do Turvo', 26),
     (4768, 'Barretos', 26),
     (4769, 'Barrinha', 26),
     (4770, 'Barueri', 26),
     (4771, 'Bastos', 26),
     (4772, 'Batatais', 26),
     (4773, 'Bauru', 26),
     (4774, 'Bebedouro', 26),
     (4775, 'Bento de Abreu', 26),
     (4776, 'Bernardino de Campos', 26),
     (4777, 'Bertioga', 26),
     (4778, 'Bilac', 26),
     (4779, 'Birigui', 26),
     (4780, 'Biritiba-Mirim', 26),
     (4781, 'Boa Esperança do Sul', 26),
     (4782, 'Bocaina', 26),
     (4783, 'Bofete', 26),
     (4784, 'Boituva', 26),
     (4785, 'Bom Jesus dos Perdões', 26),
     (4786, 'Bom Sucesso de Itararé', 26),
     (4787, 'Borá', 26),
     (4788, 'Boracéia', 26),
     (4789, 'Borborema', 26),
     (4790, 'Borebi', 26),
     (4791, 'Botucatu', 26),
     (4792, 'Bragança Paulista', 26),
     (4793, 'Braúna', 26),
     (4794, 'Brejo Alegre', 26),
     (4795, 'Brodowski', 26),
     (4796, 'Brotas', 26),
     (4797, 'Buri', 26),
     (4798, 'Buritama', 26),
     (4799, 'Buritizal', 26),
     (4800, 'Cabrália Paulista', 26),
     (4801, 'Cabreúva', 26),
     (4802, 'Caçapava', 26),
     (4803, 'Cachoeira Paulista', 26),
     (4804, 'Caconde', 26),
     (4805, 'Cafelândia', 26),
     (4806, 'Caiabu', 26),
     (4807, 'Caieiras', 26),
     (4808, 'Caiuá', 26),
     (4809, 'Cajamar', 26),
     (4810, 'Cajati', 26),
     (4811, 'Cajobi', 26),
     (4812, 'Cajuru', 26),
     (4813, 'Campina do Monte Alegre', 26),
     (4814, 'Campinas', 26),
     (4815, 'Campo Limpo Paulista', 26),
     (4816, 'Campos do Jordão', 26),
     (4817, 'Campos Novos Paulista', 26),
     (4818, 'Cananéia', 26),
     (4819, 'Canas', 26),
     (4820, 'Cândido Mota', 26),
     (4821, 'Cândido Rodrigues', 26),
     (4822, 'Canitar', 26),
     (4823, 'Capão Bonito', 26),
     (4824, 'Capela do Alto', 26),
     (4825, 'Capivari', 26),
     (4826, 'Caraguatatuba', 26),
     (4827, 'Carapicuíba', 26),
     (4828, 'Cardoso', 26),
     (4829, 'Casa Branca', 26),
     (4830, 'Cássia dos Coqueiros', 26),
     (4831, 'Castilho', 26),
     (4832, 'Catanduva', 26),
     (4833, 'Catiguá', 26),
     (4834, 'Cedral', 26),
     (4835, 'Cerqueira César', 26),
     (4836, 'Cerquilho', 26),
     (4837, 'Cesário Lange', 26),
     (4838, 'Charqueada', 26),
     (4839, 'Chavantes', 26),
     (4840, 'Clementina', 26),
     (4841, 'Colina', 26),
     (4842, 'Colômbia', 26),
     (4843, 'Conchal', 26),
     (4844, 'Conchas', 26),
     (4845, 'Cordeirópolis', 26),
     (4846, 'Coroados', 26),
     (4847, 'Coronel Macedo', 26),
     (4848, 'Corumbataí', 26),
     (4849, 'Cosmópolis', 26),
     (4850, 'Cosmorama', 26),
     (4851, 'Cotia', 26),
     (4852, 'Cravinhos', 26),
     (4853, 'Cristais Paulista', 26),
     (4854, 'Cruzália', 26),
     (4855, 'Cruzeiro', 26),
     (4856, 'Cubatão', 26),
     (4857, 'Cunha', 26),
     (4858, 'Descalvado', 26),
     (4859, 'Diadema', 26),
     (4860, 'Dirce Reis', 26),
     (4861, 'Divinolândia', 26),
     (4862, 'Dobrada', 26),
     (4863, 'Dois Córregos', 26),
     (4864, 'Dolcinópolis', 26),
     (4865, 'Dourado', 26),
     (4866, 'Dracena', 26),
     (4867, 'Duartina', 26),
     (4868, 'Dumont', 26),
     (4869, 'Echaporã', 26),
     (4870, 'Eldorado', 26),
     (4871, 'Elias Fausto', 26),
     (4872, 'Elisiário', 26),
     (4873, 'Embaúba', 26),
     (4874, 'Embu', 26),
     (4875, 'Embu-Guaçu', 26),
     (4876, 'Emilianópolis', 26),
     (4877, 'Engenheiro Coelho', 26),
     (4878, 'Espírito Santo do Pinhal', 26),
     (4879, 'Espírito Santo do Turvo', 26),
     (4880, 'Estiva Gerbi', 26),
     (4881, 'Estrela dOeste', 26),
     (4882, 'Estrela do Norte', 26),
     (4883, 'Euclides da Cunha Paulista', 26),
     (4884, 'Fartura', 26),
     (4885, 'Fernando Prestes', 26),
     (4886, 'Fernandópolis', 26),
     (4887, 'Fernão', 26),
     (4888, 'Ferraz de Vasconcelos', 26),
     (4889, 'Flora Rica', 26),
     (4890, 'Floreal', 26),
     (4891, 'Flórida Paulista', 26),
     (4892, 'Florínia', 26),
     (4893, 'Franca', 26),
     (4894, 'Francisco Morato', 26),
     (4895, 'Franco da Rocha', 26),
     (4896, 'Gabriel Monteiro', 26),
     (4897, 'Gália', 26),
     (4898, 'Garça', 26),
     (4899, 'Gastão Vidigal', 26),
     (4900, 'Gavião Peixoto', 26),
     (4901, 'General Salgado', 26),
     (4902, 'Getulina', 26),
     (4903, 'Glicério', 26),
     (4904, 'Guaiçara', 26),
     (4905, 'Guaimbê', 26),
     (4906, 'Guaíra', 26),
     (4907, 'Guapiaçu', 26),
     (4908, 'Guapiara', 26),
     (4909, 'Guará', 26),
     (4910, 'Guaraçaí', 26),
     (4911, 'Guaraci', 26),
     (4912, 'Guarani dOeste', 26),
     (4913, 'Guarantã', 26),
     (4914, 'Guararapes', 26),
     (4915, 'Guararema', 26),
     (4916, 'Guaratinguetá', 26),
     (4917, 'Guareí', 26),
     (4918, 'Guariba', 26),
     (4919, 'Guarujá', 26),
     (4920, 'Guarulhos', 26),
     (4921, 'Guatapará', 26),
     (4922, 'Guzolândia', 26),
     (4923, 'Herculândia', 26),
     (4924, 'Holambra', 26),
     (4925, 'Hortolândia', 26),
     (4926, 'Iacanga', 26),
     (4927, 'Iacri', 26),
     (4928, 'Iaras', 26),
     (4929, 'Ibaté', 26),
     (4930, 'Ibirá', 26),
     (4931, 'Ibirarema', 26),
     (4932, 'Ibitinga', 26),
     (4933, 'Ibiúna', 26),
     (4934, 'Icém', 26),
     (4935, 'Iepê', 26),
     (4936, 'Igaraçu do Tietê', 26),
     (4937, 'Igarapava', 26),
     (4938, 'Igaratá', 26),
     (4939, 'Iguape', 26),
     (4940, 'Ilha Comprida', 26),
     (4941, 'Ilha Solteira', 26),
     (4942, 'Ilhabela', 26),
     (4943, 'Indaiatuba', 26),
     (4944, 'Indiana', 26),
     (4945, 'Indiaporã', 26),
     (4946, 'Inúbia Paulista', 26),
     (4947, 'Ipaussu', 26),
     (4948, 'Iperó', 26),
     (4949, 'Ipeúna', 26),
     (4950, 'Ipiguá', 26),
     (4951, 'Iporanga', 26),
     (4952, 'Ipuã', 26),
     (4953, 'Iracemápolis', 26),
     (4954, 'Irapuã', 26),
     (4955, 'Irapuru', 26),
     (4956, 'Itaberá', 26),
     (4957, 'Itaí', 26),
     (4958, 'Itajobi', 26),
     (4959, 'Itaju', 26),
     (4960, 'Itanhaém', 26),
     (4961, 'Itaóca', 26),
     (4962, 'Itapecerica da Serra', 26),
     (4963, 'Itapetininga', 26),
     (4964, 'Itapeva', 26),
     (4965, 'Itapevi', 26),
     (4966, 'Itapira', 26),
     (4967, 'Itapirapuã Paulista', 26),
     (4968, 'Itápolis', 26),
     (4969, 'Itaporanga', 26),
     (4970, 'Itapuí', 26),
     (4971, 'Itapura', 26),
     (4972, 'Itaquaquecetuba', 26),
     (4973, 'Itararé', 26),
     (4974, 'Itariri', 26),
     (4975, 'Itatiba', 26),
     (4976, 'Itatinga', 26),
     (4977, 'Itirapina', 26),
     (4978, 'Itirapuã', 26),
     (4979, 'Itobi', 26),
     (4980, 'Itu', 26),
     (4981, 'Itupeva', 26),
     (4982, 'Ituverava', 26),
     (4983, 'Jaborandi', 26),
     (4984, 'Jaboticabal', 26),
     (4985, 'Jacareí', 26),
     (4986, 'Jaci', 26),
     (4987, 'Jacupiranga', 26),
     (4988, 'Jaguariúna', 26),
     (4989, 'Jales', 26),
     (4990, 'Jambeiro', 26),
     (4991, 'Jandira', 26),
     (4992, 'Jardinópolis', 26),
     (4993, 'Jarinu', 26),
     (4994, 'Jaú', 26),
     (4995, 'Jeriquara', 26),
     (4996, 'Joanópolis', 26),
     (4997, 'João Ramalho', 26),
     (4998, 'José Bonifácio', 26),
     (4999, 'Júlio Mesquita', 26),
     (5000, 'Jumirim', 26),
     (5001, 'Jundiaí', 26),
     (5002, 'Junqueirópolis', 26),
     (5003, 'Juquiá', 26),
     (5004, 'Juquitiba', 26),
     (5005, 'Lagoinha', 26),
     (5006, 'Laranjal Paulista', 26),
     (5007, 'Lavínia', 26),
     (5008, 'Lavrinhas', 26),
     (5009, 'Leme', 26),
     (5010, 'Lençóis Paulista', 26),
     (5011, 'Limeira', 26),
     (5012, 'Lindóia', 26),
     (5013, 'Lins', 26),
     (5014, 'Lorena', 26),
     (5015, 'Lourdes', 26),
     (5016, 'Louveira', 26),
     (5017, 'Lucélia', 26),
     (5018, 'Lucianópolis', 26),
     (5019, 'Luís Antônio', 26),
     (5020, 'Luiziânia', 26),
     (5021, 'Lupércio', 26),
     (5022, 'Lutécia', 26),
     (5023, 'Macatuba', 26),
     (5024, 'Macaubal', 26),
     (5025, 'Macedônia', 26),
     (5026, 'Magda', 26),
     (5027, 'Mairinque', 26),
     (5028, 'Mairiporã', 26),
     (5029, 'Manduri', 26),
     (5030, 'Marabá Paulista', 26),
     (5031, 'Maracaí', 26),
     (5032, 'Marapoama', 26),
     (5033, 'Mariápolis', 26),
     (5034, 'Marília', 26),
     (5035, 'Marinópolis', 26),
     (5036, 'Martinópolis', 26),
     (5037, 'Matão', 26),
     (5038, 'Mauá', 26),
     (5039, 'Mendonça', 26),
     (5040, 'Meridiano', 26),
     (5041, 'Mesópolis', 26),
     (5042, 'Miguelópolis', 26),
     (5043, 'Mineiros do Tietê', 26),
     (5044, 'Mira Estrela', 26),
     (5045, 'Miracatu', 26),
     (5046, 'Mirandópolis', 26),
     (5047, 'Mirante do Paranapanema', 26),
     (5048, 'Mirassol', 26),
     (5049, 'Mirassolândia', 26),
     (5050, 'Mococa', 26),
     (5051, 'Mogi das Cruzes', 26),
     (5052, 'Mogi Guaçu', 26),
     (5053, 'Moji Mirim', 26),
     (5054, 'Mombuca', 26),
     (5055, 'Monções', 26),
     (5056, 'Mongaguá', 26),
     (5057, 'Monte Alegre do Sul', 26),
     (5058, 'Monte Alto', 26),
     (5059, 'Monte Aprazível', 26),
     (5060, 'Monte Azul Paulista', 26),
     (5061, 'Monte Castelo', 26),
     (5062, 'Monte Mor', 26),
     (5063, 'Monteiro Lobato', 26),
     (5064, 'Morro Agudo', 26),
     (5065, 'Morungaba', 26),
     (5066, 'Motuca', 26),
     (5067, 'Murutinga do Sul', 26),
     (5068, 'Nantes', 26),
     (5069, 'Narandiba', 26),
     (5070, 'Natividade da Serra', 26),
     (5071, 'Nazaré Paulista', 26),
     (5072, 'Neves Paulista', 26),
     (5073, 'Nhandeara', 26),
     (5074, 'Nipoã', 26),
     (5075, 'Nova Aliança', 26),
     (5076, 'Nova Campina', 26),
     (5077, 'Nova Canaã Paulista', 26),
     (5078, 'Nova Castilho', 26),
     (5079, 'Nova Europa', 26),
     (5080, 'Nova Granada', 26),
     (5081, 'Nova Guataporanga', 26),
     (5082, 'Nova Independência', 26),
     (5083, 'Nova Luzitânia', 26),
     (5084, 'Nova Odessa', 26),
     (5085, 'Novais', 26),
     (5086, 'Novo Horizonte', 26),
     (5087, 'Nuporanga', 26),
     (5088, 'Ocauçu', 26),
     (5089, 'Óleo', 26),
     (5090, 'Olímpia', 26),
     (5091, 'Onda Verde', 26),
     (5092, 'Oriente', 26),
     (5093, 'Orindiúva', 26),
     (5094, 'Orlândia', 26),
     (5095, 'Osasco', 26),
     (5096, 'Oscar Bressane', 26),
     (5097, 'Osvaldo Cruz', 26),
     (5098, 'Ourinhos', 26),
     (5099, 'Ouro Verde', 26),
     (5100, 'Ouroeste', 26),
     (5101, 'Pacaembu', 26),
     (5102, 'Palestina', 26),
     (5103, 'Palmares Paulista', 26),
     (5104, 'Palmeira dOeste', 26),
     (5105, 'Palmital', 26),
     (5106, 'Panorama', 26),
     (5107, 'Paraguaçu Paulista', 26),
     (5108, 'Paraibuna', 26),
     (5109, 'Paraíso', 26),
     (5110, 'Paranapanema', 26),
     (5111, 'Paranapuã', 26),
     (5112, 'Parapuã', 26),
     (5113, 'Pardinho', 26),
     (5114, 'Pariquera-Açu', 26),
     (5115, 'Parisi', 26),
     (5116, 'Patrocínio Paulista', 26),
     (5117, 'Paulicéia', 26),
     (5118, 'Paulínia', 26),
     (5119, 'Paulistânia', 26),
     (5120, 'Paulo de Faria', 26),
     (5121, 'Pederneiras', 26),
     (5122, 'Pedra Bela', 26),
     (5123, 'Pedranópolis', 26),
     (5124, 'Pedregulho', 26),
     (5125, 'Pedreira', 26),
     (5126, 'Pedrinhas Paulista', 26),
     (5127, 'Pedro de Toledo', 26),
     (5128, 'Penápolis', 26),
     (5129, 'Pereira Barreto', 26),
     (5130, 'Pereiras', 26),
     (5131, 'Peruíbe', 26),
     (5132, 'Piacatu', 26),
     (5133, 'Piedade', 26),
     (5134, 'Pilar do Sul', 26),
     (5135, 'Pindamonhangaba', 26),
     (5136, 'Pindorama', 26),
     (5137, 'Pinhalzinho', 26),
     (5138, 'Piquerobi', 26),
     (5139, 'Piquete', 26),
     (5140, 'Piracaia', 26),
     (5141, 'Piracicaba', 26),
     (5142, 'Piraju', 26),
     (5143, 'Pirajuí', 26),
     (5144, 'Pirangi', 26),
     (5145, 'Pirapora do Bom Jesus', 26),
     (5146, 'Pirapozinho', 26),
     (5147, 'Pirassununga', 26),
     (5148, 'Piratininga', 26),
     (5149, 'Pitangueiras', 26),
     (5150, 'Planalto', 26),
     (5151, 'Platina', 26),
     (5152, 'Poá', 26),
     (5153, 'Poloni', 26),
     (5154, 'Pompéia', 26),
     (5155, 'Pongaí', 26),
     (5156, 'Pontal', 26),
     (5157, 'Pontalinda', 26),
     (5158, 'Pontes Gestal', 26),
     (5159, 'Populina', 26),
     (5160, 'Porangaba', 26),
     (5161, 'Porto Feliz', 26),
     (5162, 'Porto Ferreira', 26),
     (5163, 'Potim', 26),
     (5164, 'Potirendaba', 26),
     (5165, 'Pracinha', 26),
     (5166, 'Pradópolis', 26),
     (5167, 'Praia Grande', 26),
     (5168, 'Pratânia', 26),
     (5169, 'Presidente Alves', 26),
     (5170, 'Presidente Bernardes', 26),
     (5171, 'Presidente Epitácio', 26),
     (5172, 'Presidente Prudente', 26),
     (5173, 'Presidente Venceslau', 26),
     (5174, 'Promissão', 26),
     (5175, 'Quadra', 26),
     (5176, 'Quatá', 26),
     (5177, 'Queiroz', 26),
     (5178, 'Queluz', 26),
     (5179, 'Quintana', 26),
     (5180, 'Rafard', 26),
     (5181, 'Rancharia', 26),
     (5182, 'Redenção da Serra', 26),
     (5183, 'Regente Feijó', 26),
     (5184, 'Reginópolis', 26),
     (5185, 'Registro', 26),
     (5186, 'Restinga', 26),
     (5187, 'Ribeira', 26),
     (5188, 'Ribeirão Bonito', 26),
     (5189, 'Ribeirão Branco', 26),
     (5190, 'Ribeirão Corrente', 26),
     (5191, 'Ribeirão do Sul', 26),
     (5192, 'Ribeirão dos Índios', 26),
     (5193, 'Ribeirão Grande', 26),
     (5194, 'Ribeirão Pires', 26),
     (5195, 'Ribeirão Preto', 26),
     (5196, 'Rifaina', 26),
     (5197, 'Rincão', 26),
     (5198, 'Rinópolis', 26),
     (5199, 'Rio Claro', 26),
     (5200, 'Rio das Pedras', 26),
     (5201, 'Rio Grande da Serra', 26),
     (5202, 'Riolândia', 26),
     (5203, 'Riversul', 26),
     (5204, 'Rosana', 26),
     (5205, 'Roseira', 26),
     (5206, 'Rubiácea', 26),
     (5207, 'Rubinéia', 26),
     (5208, 'Sabino', 26),
     (5209, 'Sagres', 26),
     (5210, 'Sales', 26),
     (5211, 'Sales Oliveira', 26),
     (5212, 'Salesópolis', 26),
     (5213, 'Salmourão', 26),
     (5214, 'Saltinho', 26),
     (5215, 'Salto', 26),
     (5216, 'Salto de Pirapora', 26),
     (5217, 'Salto Grande', 26),
     (5218, 'Sandovalina', 26),
     (5219, 'Santa Adélia', 26),
     (5220, 'Santa Albertina', 26),
     (5221, 'Santa Bárbara dOeste', 26),
     (5222, 'Santa Branca', 26),
     (5223, 'Santa Clara dOeste', 26),
     (5224, 'Santa Cruz da Conceição', 26),
     (5225, 'Santa Cruz da Esperança', 26),
     (5226, 'Santa Cruz das Palmeiras', 26),
     (5227, 'Santa Cruz do Rio Pardo', 26),
     (5228, 'Santa Ernestina', 26),
     (5229, 'Santa Fé do Sul', 26),
     (5230, 'Santa Gertrudes', 26),
     (5231, 'Santa Isabel', 26),
     (5232, 'Santa Lúcia', 26),
     (5233, 'Santa Maria da Serra', 26),
     (5234, 'Santa Mercedes', 26),
     (5235, 'Santa Rita dOeste', 26),
     (5236, 'Santa Rita do Passa Quatro', 26),
     (5237, 'Santa Rosa de Viterbo', 26),
     (5238, 'Santa Salete', 26),
     (5239, 'Santana da Ponte Pensa', 26),
     (5240, 'Santana de Parnaíba', 26),
     (5241, 'Santo Anastácio', 26),
     (5242, 'Santo André', 26),
     (5243, 'Santo Antônio da Alegria', 26),
     (5244, 'Santo Antônio de Posse', 26),
     (5245, 'Santo Antônio do Aracanguá', 26),
     (5246, 'Santo Antônio do Jardim', 26),
     (5247, 'Santo Antônio do Pinhal', 26),
     (5248, 'Santo Expedito', 26),
     (5249, 'Santópolis do Aguapeí', 26),
     (5250, 'Santos', 26),
     (5251, 'São Bento do Sapucaí', 26),
     (5252, 'São Bernardo do Campo', 26),
     (5253, 'São Caetano do Sul', 26),
     (5254, 'São Carlos', 26),
     (5255, 'São Francisco', 26),
     (5256, 'São João da Boa Vista', 26),
     (5257, 'São João das Duas Pontes', 26),
     (5258, 'São João de Iracema', 26),
     (5259, 'São João do Pau dAlho', 26),
     (5260, 'São Joaquim da Barra', 26),
     (5261, 'São José da Bela Vista', 26),
     (5262, 'São José do Barreiro', 26),
     (5263, 'São José do Rio Pardo', 26),
     (5264, 'São José do Rio Preto', 26),
     (5265, 'São José dos Campos', 26),
     (5266, 'São Lourenço da Serra', 26),
     (5267, 'São Luís do Paraitinga', 26),
     (5268, 'São Manuel', 26),
     (5269, 'São Miguel Arcanjo', 26),
     (5270, 'São Paulo', 26),
     (5271, 'São Pedro', 26),
     (5272, 'São Pedro do Turvo', 26),
     (5273, 'São Roque', 26),
     (5274, 'São Sebastião', 26),
     (5275, 'São Sebastião da Grama', 26),
     (5276, 'São Simão', 26),
     (5277, 'São Vicente', 26),
     (5278, 'Sarapuí', 26),
     (5279, 'Sarutaiá', 26),
     (5280, 'Sebastianópolis do Sul', 26),
     (5281, 'Serra Azul', 26),
     (5282, 'Serra Negra', 26),
     (5283, 'Serrana', 26),
     (5284, 'Sertãozinho', 26),
     (5285, 'Sete Barras', 26),
     (5286, 'Severínia', 26),
     (5287, 'Silveiras', 26),
     (5288, 'Socorro', 26),
     (5289, 'Sorocaba', 26),
     (5290, 'Sud Mennucci', 26),
     (5291, 'Sumaré', 26),
     (5292, 'Suzanápolis', 26),
     (5293, 'Suzano', 26),
     (5294, 'Tabapuã', 26),
     (5295, 'Tabatinga', 26),
     (5296, 'Taboão da Serra', 26),
     (5297, 'Taciba', 26),
     (5298, 'Taguaí', 26),
     (5299, 'Taiaçu', 26),
     (5300, 'Taiúva', 26),
     (5301, 'Tambaú', 26),
     (5302, 'Tanabi', 26),
     (5303, 'Tapiraí', 26),
     (5304, 'Tapiratiba', 26),
     (5305, 'Taquaral', 26),
     (5306, 'Taquaritinga', 26),
     (5307, 'Taquarituba', 26),
     (5308, 'Taquarivaí', 26),
     (5309, 'Tarabai', 26),
     (5310, 'Tarumã', 26),
     (5311, 'Tatuí', 26),
     (5312, 'Taubaté', 26),
     (5313, 'Tejupá', 26),
     (5314, 'Teodoro Sampaio', 26),
     (5315, 'Terra Roxa', 26),
     (5316, 'Tietê', 26),
     (5317, 'Timburi', 26),
     (5318, 'Torre de Pedra', 26),
     (5319, 'Torrinha', 26),
     (5320, 'Trabiju', 26),
     (5321, 'Tremembé', 26),
     (5322, 'Três Fronteiras', 26),
     (5323, 'Tuiuti', 26),
     (5324, 'Tupã', 26),
     (5325, 'Tupi Paulista', 26),
     (5326, 'Turiúba', 26),
     (5327, 'Turmalina', 26),
     (5328, 'Ubarana', 26),
     (5329, 'Ubatuba', 26),
     (5330, 'Ubirajara', 26),
     (5331, 'Uchoa', 26),
     (5332, 'União Paulista', 26),
     (5333, 'Urânia', 26),
     (5334, 'Uru', 26),
     (5335, 'Urupês', 26),
     (5336, 'Valentim Gentil', 26),
     (5337, 'Valinhos', 26),
     (5338, 'Valparaíso', 26),
     (5339, 'Vargem', 26),
     (5340, 'Vargem Grande do Sul', 26),
     (5341, 'Vargem Grande Paulista', 26),
     (5342, 'Várzea Paulista', 26),
     (5343, 'Vera Cruz', 26),
     (5344, 'Vinhedo', 26),
     (5345, 'Viradouro', 26),
     (5346, 'Vista Alegre do Alto', 26),
     (5347, 'Vitória Brasil', 26),
     (5348, 'Votorantim', 26),
     (5349, 'Votuporanga', 26),
     (5350, 'Zacarias', 26),
     (5351, 'Amparo de São Francisco', 25),
     (5352, 'Aquidabã', 25),
     (5353, 'Aracaju', 25),
     (5354, 'Arauá', 25),
     (5355, 'Areia Branca', 25),
     (5356, 'Barra dos Coqueiros', 25),
     (5357, 'Boquim', 25),
     (5358, 'Brejo Grande', 25),
     (5359, 'Campo do Brito', 25),
     (5360, 'Canhoba', 25),
     (5361, 'Canindé de São Francisco', 25),
     (5362, 'Capela', 25),
     (5363, 'Carira', 25),
     (5364, 'Carmópolis', 25),
     (5365, 'Cedro de São João', 25),
     (5366, 'Cristinápolis', 25),
     (5367, 'Cumbe', 25),
     (5368, 'Divina Pastora', 25),
     (5369, 'Estância', 25),
     (5370, 'Feira Nova', 25),
     (5371, 'Frei Paulo', 25),
     (5372, 'Gararu', 25),
     (5373, 'General Maynard', 25),
     (5374, 'Gracho Cardoso', 25),
     (5375, 'Ilha das Flores', 25),
     (5376, 'Indiaroba', 25),
     (5377, 'Itabaiana', 25),
     (5378, 'Itabaianinha', 25),
     (5379, 'Itabi', 25),
     (5380, 'Itaporanga dAjuda', 25),
     (5381, 'Japaratuba', 25),
     (5382, 'Japoatã', 25),
     (5383, 'Lagarto', 25),
     (5384, 'Laranjeiras', 25),
     (5385, 'Macambira', 25),
     (5386, 'Malhada dos Bois', 25),
     (5387, 'Malhador', 25),
     (5388, 'Maruim', 25),
     (5389, 'Moita Bonita', 25),
     (5390, 'Monte Alegre de Sergipe', 25),
     (5391, 'Muribeca', 25),
     (5392, 'Neópolis', 25),
     (5393, 'Nossa Senhora Aparecida', 25),
     (5394, 'Nossa Senhora da Glória', 25),
     (5395, 'Nossa Senhora das Dores', 25),
     (5396, 'Nossa Senhora de Lourdes', 25),
     (5397, 'Nossa Senhora do Socorro', 25),
     (5398, 'Pacatuba', 25),
     (5399, 'Pedra Mole', 25),
     (5400, 'Pedrinhas', 25),
     (5401, 'Pinhão', 25),
     (5402, 'Pirambu', 25),
     (5403, 'Poço Redondo', 25),
     (5404, 'Poço Verde', 25),
     (5405, 'Porto da Folha', 25),
     (5406, 'Propriá', 25),
     (5407, 'Riachão do Dantas', 25),
     (5408, 'Riachuelo', 25),
     (5409, 'Ribeirópolis', 25),
     (5410, 'Rosário do Catete', 25),
     (5411, 'Salgado', 25),
     (5412, 'Santa Luzia do Itanhy', 25),
     (5413, 'Santa Rosa de Lima', 25),
     (5414, 'Santana do São Francisco', 25),
     (5415, 'Santo Amaro das Brotas', 25),
     (5416, 'São Cristóvão', 25),
     (5417, 'São Domingos', 25),
     (5418, 'São Francisco', 25),
     (5419, 'São Miguel do Aleixo', 25),
     (5420, 'Simão Dias', 25),
     (5421, 'Siriri', 25),
     (5422, 'Telha', 25),
     (5423, 'Tobias Barreto', 25),
     (5424, 'Tomar do Geru', 25),
     (5425, 'Umbaúba', 25),
     (5426, 'Abreulândia', 27),
     (5427, 'Aguiarnópolis', 27),
     (5428, 'Aliança do Tocantins', 27),
     (5429, 'Almas', 27),
     (5430, 'Alvorada', 27),
     (5431, 'Ananás', 27),
     (5432, 'Angico', 27),
     (5433, 'Aparecida do Rio Negro', 27),
     (5434, 'Aragominas', 27),
     (5435, 'Araguacema', 27),
     (5436, 'Araguaçu', 27),
     (5437, 'Araguaína', 27),
     (5438, 'Araguanã', 27),
     (5439, 'Araguatins', 27),
     (5440, 'Arapoema', 27),
     (5441, 'Arraias', 27),
     (5442, 'Augustinópolis', 27),
     (5443, 'Aurora do Tocantins', 27),
     (5444, 'Axixá do Tocantins', 27),
     (5445, 'Babaçulândia', 27),
     (5446, 'Bandeirantes do Tocantins', 27),
     (5447, 'Barra do Ouro', 27),
     (5448, 'Barrolândia', 27),
     (5449, 'Bernardo Sayão', 27),
     (5450, 'Bom Jesus do Tocantins', 27),
     (5451, 'Brasilândia do Tocantins', 27),
     (5452, 'Brejinho de Nazaré', 27),
     (5453, 'Buriti do Tocantins', 27),
     (5454, 'Cachoeirinha', 27),
     (5455, 'Campos Lindos', 27),
     (5456, 'Cariri do Tocantins', 27),
     (5457, 'Carmolândia', 27),
     (5458, 'Carrasco Bonito', 27),
     (5459, 'Caseara', 27),
     (5460, 'Centenário', 27),
     (5461, 'Chapada da Natividade', 27),
     (5462, 'Chapada de Areia', 27),
     (5463, 'Colinas do Tocantins', 27),
     (5464, 'Colméia', 27),
     (5465, 'Combinado', 27),
     (5466, 'Conceição do Tocantins', 27),
     (5467, 'Couto de Magalhães', 27),
     (5468, 'Cristalândia', 27),
     (5469, 'Crixás do Tocantins', 27),
     (5470, 'Darcinópolis', 27),
     (5471, 'Dianópolis', 27),
     (5472, 'Divinópolis do Tocantins', 27),
     (5473, 'Dois Irmãos do Tocantins', 27),
     (5474, 'Dueré', 27),
     (5475, 'Esperantina', 27),
     (5476, 'Fátima', 27),
     (5477, 'Figueirópolis', 27),
     (5478, 'Filadélfia', 27),
     (5479, 'Formoso do Araguaia', 27),
     (5480, 'Fortaleza do Tabocão', 27),
     (5481, 'Goianorte', 27),
     (5482, 'Goiatins', 27),
     (5483, 'Guaraí', 27),
     (5484, 'Gurupi', 27),
     (5485, 'Ipueiras', 27),
     (5486, 'Itacajá', 27),
     (5487, 'Itaguatins', 27),
     (5488, 'Itapiratins', 27),
     (5489, 'Itaporã do Tocantins', 27),
     (5490, 'Jaú do Tocantins', 27),
     (5491, 'Juarina', 27),
     (5492, 'Lagoa da Confusão', 27),
     (5493, 'Lagoa do Tocantins', 27),
     (5494, 'Lajeado', 27),
     (5495, 'Lavandeira', 27),
     (5496, 'Lizarda', 27),
     (5497, 'Luzinópolis', 27),
     (5498, 'Marianópolis do Tocantins', 27),
     (5499, 'Mateiros', 27),
     (5500, 'Maurilândia do Tocantins', 27),
     (5501, 'Miracema do Tocantins', 27),
     (5502, 'Miranorte', 27),
     (5503, 'Monte do Carmo', 27),
     (5504, 'Monte Santo do Tocantins', 27),
     (5505, 'Muricilândia', 27),
     (5506, 'Natividade', 27),
     (5507, 'Nazaré', 27),
     (5508, 'Nova Olinda', 27),
     (5509, 'Nova Rosalândia', 27),
     (5510, 'Novo Acordo', 27),
     (5511, 'Novo Alegre', 27),
     (5512, 'Novo Jardim', 27),
     (5513, 'Oliveira de Fátima', 27),
     (5514, 'Palmas', 27),
     (5515, 'Palmeirante', 27),
     (5516, 'Palmeiras do Tocantins', 27),
     (5517, 'Palmeirópolis', 27),
     (5518, 'Paraíso do Tocantins', 27),
     (5519, 'Paranã', 27),
     (5520, 'Pau dArco', 27),
     (5521, 'Pedro Afonso', 27),
     (5522, 'Peixe', 27),
     (5523, 'Pequizeiro', 27),
     (5524, 'Pindorama do Tocantins', 27),
     (5525, 'Piraquê', 27),
     (5526, 'Pium', 27),
     (5527, 'Ponte Alta do Bom Jesus', 27),
     (5528, 'Ponte Alta do Tocantins', 27),
     (5529, 'Porto Alegre do Tocantins', 27),
     (5530, 'Porto Nacional', 27),
     (5531, 'Praia Norte', 27),
     (5532, 'Presidente Kennedy', 27),
     (5533, 'Pugmil', 27),
     (5534, 'Recursolândia', 27),
     (5535, 'Riachinho', 27),
     (5536, 'Rio da Conceição', 27),
     (5537, 'Rio dos Bois', 27),
     (5538, 'Rio Sono', 27),
     (5539, 'Sampaio', 27),
     (5540, 'Sandolândia', 27),
     (5541, 'Santa Fé do Araguaia', 27),
     (5542, 'Santa Maria do Tocantins', 27),
     (5543, 'Santa Rita do Tocantins', 27),
     (5544, 'Santa Rosa do Tocantins', 27),
     (5545, 'Santa Tereza do Tocantins', 27),
     (5546, 'Santa Terezinha do Tocantins', 27),
     (5547, 'São Bento do Tocantins', 27),
     (5548, 'São Félix do Tocantins', 27),
     (5549, 'São Miguel do Tocantins', 27),
     (5550, 'São Salvador do Tocantins', 27),
     (5551, 'São Sebastião do Tocantins', 27),
     (5552, 'São Valério da Natividade', 27),
     (5553, 'Silvanópolis', 27),
     (5554, 'Sítio Novo do Tocantins', 27),
     (5555, 'Sucupira', 27),
     (5556, 'Taguatinga', 27),
     (5557, 'Taipas do Tocantins', 27),
     (5558, 'Talismã', 27),
     (5559, 'Tocantínia', 27),
     (5560, 'Tocantinópolis', 27),
     (5561, 'Tupirama', 27),
     (5562, 'Tupiratins', 27),
     (5563, 'Wanderlândia', 27),
     (5564, 'Xambioá', 27);


update cidade set capital = true where id =   94;
update cidade set capital = true where id =  147;
update cidade set capital = true where id =  256;
update cidade set capital = true where id =  209;
update cidade set capital = true where id =  616;
update cidade set capital = true where id =  756;
update cidade set capital = true where id =  882;
update cidade set capital = true where id =   78;
update cidade set capital = true where id =  977;
update cidade set capital = true where id = 1314;
update cidade set capital = true where id = 1630;
update cidade set capital = true where id = 1506;
update cidade set capital = true where id = 1383;
update cidade set capital = true where id = 2436;
update cidade set capital = true where id = 2655;
update cidade set capital = true where id = 3315;
update cidade set capital = true where id = 3582;
update cidade set capital = true where id = 2878;
update cidade set capital = true where id = 3658;
update cidade set capital = true where id = 3770;
update cidade set capital = true where id = 4382;
update cidade set capital = true where id = 4400;
update cidade set capital = true where id = 4174;
update cidade set capital = true where id = 4500;
update cidade set capital = true where id = 5353;
update cidade set capital = true where id = 5270;
update cidade set capital = true where id = 5514;

-- ###################################################

INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Wendy Parker', '96557866635', 4871, '1994-04-16');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Stephanie Frami', '19485406486', 3572, '1968-10-01');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Stewart Lesch', '88344327169', 5124, '1946-05-09');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Mr. Victor Langosh', '16057371750', 4264, '2005-11-20');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Dr. Elijah Welch', '42006254770', 1672, '1967-05-27');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Suzanne Kreiger', '23828465229', 3931, '1993-11-04');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Phillip Larkin', '92109749005', 2557, '1955-10-19');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Eva Grant', '50975015385', 3131, '1971-02-23');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Mr. Charlie Boyle', '65390772950', 3068, '1966-04-15');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Andre Nitzsche', '56791574394', 4729, '1996-07-27');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Kristy Champlin', '24584371579', 1641, '1949-07-11');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Yolanda Hayes', '15001098718', 1937, '1995-11-17');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Edwin Padberg-Jenkins', '83501903054', 3763, '1969-09-24');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Sabrina Padberg', '64679427690', 4608, '1971-01-29');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Mrs. Maxine Friesen V', '24459834133', 2854, '2005-03-18');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Ms. Gladys Gerlach DVM', '66305656330', 1636, '1985-05-25');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Brendan Hudson', '69605367495', 1228, '1990-01-29');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Eula Conroy', '17490833525', 1677, '1990-10-12');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Nichole Greenholt', '19587015325', 1141, '2001-04-06');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Gene Ebert', '85853507263', 1962, '1955-03-07');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Mr. Randall Leffler', '35749191804', 92, '1967-06-16');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Priscilla Bradtke', '23221756195', 4441, '1955-07-04');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Ana Doyle IV', '39827031080', 3021, '1961-05-16');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Rhonda Lang', '14249534476', 2529, '1961-07-05');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Johnathan West', '58770569977', 2515, '2004-08-21');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Lucia Stehr', '22597653071', 2356, '1971-10-22');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Naomi Mueller', '80676479214', 5089, '1953-02-06');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('George Botsford', '10375859509', 1805, '1996-04-03');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Ms. Darla Lubowitz', '19419911302', 5508, '1945-07-31');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Ms. Marcella Roob', '90298855405', 1447, '1985-12-06');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Paulette Schamberger', '11376066462', 4721, '1970-05-08');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Jasmine Gibson', '16157706958', 1509, '1960-11-04');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Terri Heathcote', '95473400382', 984, '1953-07-18');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Lynn Koss', '34315162793', 397, '1973-02-08');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Lauren Satterfield Sr.', '15212137377', 158, '1961-09-10');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Mrs. Tina Bashirian-Dicki', '16934834191', 4597, '1949-10-25');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Miss Sheri VonRueden', '83704879550', 475, '1964-10-07');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Mr. Martin Bernier', '15973079497', 2419, '1955-04-10');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Olga Rodriguez', '65633274903', 1689, '1960-10-05');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Belinda Torp', '37461017474', 4128, '1968-05-03');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Laurie Dicki-Gerlach', '12292237471', 823, '1951-03-27');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Jennifer Barton', '32366214129', 4072, '1979-06-21');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Jennifer Mraz', '53056442959', 3667, '1981-11-23');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Mack Sanford', '23384090758', 384, '1991-07-16');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Susie Kshlerin', '34382612782', 2589, '1969-12-07');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Maria Roberts', '19923514775', 4020, '1976-12-13');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Jan Daugherty', '34157850500', 1469, '1979-09-27');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Doug Collier', '73407530060', 4835, '1993-06-03');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Kirk Bailey', '20527850974', 4513, '1981-09-23');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Dr. Scott Huel-Marks', '34376739759', 4562, '1947-02-17');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Jay Kautzer', '91944076133', 2841, '1962-11-25');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Eric Koepp Sr.', '11278887333', 2078, '1948-05-04');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Mr. Ed Hagenes DVM', '40126248679', 582, '1949-12-28');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Preston Bins', '70522332009', 3917, '1998-09-24');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Dr. Kim Hessel', '38214249717', 1490, '2002-01-24');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Sandy Macejkovic', '10883004926', 4430, '1984-05-24');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Bill Lang DVM', '51078534377', 1587, '1950-03-18');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Janice Douglas', '51426551331', 188, '1959-10-20');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Marcia Bergstrom I', '27473898644', 2016, '1945-11-29');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Dr. Wilson Haag', '17525557636', 2829, '1963-01-18');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Arturo Pfeffer', '98824500890', 5099, '1965-08-15');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Sherman Buckridge V', '27020809964', 5036, '1982-07-27');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Dr. Sergio Hills', '30857885636', 5516, '1952-06-16');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Chad Kautzer', '10931252929', 242, '1997-02-17');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Ramiro Konopelski', '55102777855', 1378, '1948-06-05');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Julian Hickle', '24446986868', 2350, '2001-10-14');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('William Kuphal I', '77285105654', 2, '1957-05-23');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Sergio Considine', '99361437030', 5139, '1961-09-13');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Mr. Douglas Prosacco', '51100902678', 5556, '1987-08-26');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Cynthia Thompson', '97406881080', 3914, '2000-09-26');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Malcolm Schroeder', '13184281348', 35, '1974-03-25');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Mr. Terence Johnson', '90677955507', 2352, '1967-03-22');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Casey Gislason', '22038726107', 1221, '1987-01-23');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Karl Balistreri IV', '32959580425', 2561, '1961-05-01');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Bradley Hilpert', '80098249232', 3704, '2005-01-10');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Helen Koss Jr.', '37411033282', 3810, '1950-01-31');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Gabriel Witting', '99721456801', 309, '2002-01-05');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Traci Larkin', '52848701659', 358, '1951-11-29');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Rachel Gorczany', '14284650157', 2206, '1952-08-10');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Angelica Considine', '48079143845', 2803, '1967-12-18');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Madeline Hackett', '98260297797', 1555, '1985-03-04');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Ronnie McGlynn PhD', '31305712853', 2649, '1946-06-16');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Carlos Blick', '11266060610', 5072, '1977-05-15');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Dr. Mario Becker', '82558624169', 5280, '1999-01-30');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Shelly Farrell-Skiles', '53247053853', 793, '1968-04-29');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Orlando Hermiston', '79525791503', 1130, '1994-09-18');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Dr. Levi Koepp', '14496443357', 816, '1998-02-28');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Dr. Shane Yundt-Volkman', '99158609870', 1415, '1960-04-16');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Rogelio Senger', '11328783998', 4590, '1991-02-09');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Guy Bednar', '13470761950', 739, '1957-07-31');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Eunice Rempel', '73514873464', 2509, '1987-07-12');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Lynn Blanda', '90002893759', 5410, '1997-08-07');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Blanca Bailey', '13646618805', 1676, '2002-07-18');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Elmer Boyle', '76461259719', 5350, '1982-06-11');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Tracy Deckow', '85898544598', 3553, '1957-05-13');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Cynthia Bailey', '40642539039', 4140, '1994-10-09');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Sylvia Toy', '33209108560', 2934, '1993-12-25');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Miss Marcella Kilback', '28525549828', 230, '1992-06-10');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Alvin Stracke', '44202878348', 5455, '1994-05-29');
INSERT INTO cliente (nome, cpf, cidade_id, data_nascimento) VALUES ('Marcus Rolfson-Ortiz', '61430378437', 4716, '1968-09-15');

INSERT INTO loja (cidade_id, data_inauguracao) VALUES (967, '1943-05-11');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (4700, '1956-12-03');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (3087, '1981-05-24');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (4762, '1984-04-23');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (88, '1943-08-23');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (5080, '2005-05-09');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (2083, '1967-01-23');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (3803, '1995-11-24');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (4576, '1960-10-22');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (1786, '1960-07-31');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (4897, '1961-11-12');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (5243, '1959-07-01');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (4781, '2001-03-04');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (3583, '1996-11-04');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (3484, '2001-06-19');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (5165, '1955-02-19');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (3898, '1955-01-07');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (4177, '1950-01-25');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (302, '1975-06-14');
INSERT INTO loja (cidade_id, data_inauguracao) VALUES (4936, '1962-11-26');

INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Jessie Jacobs', '49075676852', 6, '1959-02-02');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Santiago Mante', '32914553214', 15, '1982-10-27');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Esther Sauer', '16900316437', 17, '2001-10-11');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Dawn Huel', '42142795296', 9, '1989-02-17');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Darrell Jaskolski', '29239068285', 17, '1974-06-07');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Wesley Price', '45814994603', 10, '1953-01-12');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Iris Schultz', '44126642118', 13, '1963-03-11');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Dr. Harry Schinner', '58322762416', 20, '1968-09-29');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Leroy Bernier', '25600343407', 4, '1960-12-12');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Beatrice Hagenes', '96622213763', 4, '1946-05-07');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Martin Bergnaum', '98641251712', 19, '1972-01-22');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Dr. Bennie Jenkins', '88887087660', 9, '1972-09-08');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Shirley Abbott', '91383270602', 6, '1954-03-24');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Guy Shields', '92536800270', 2, '2005-08-21');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Georgia Torphy-Ritchie', '70865671127', 2, '1959-02-15');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Eddie Bauch', '14263310125', 1, '1944-01-31');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Rhonda Haag', '26907705641', 11, '1975-08-11');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Edward Fritsch', '98771698663', 10, '1996-11-21');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('David Ferry II', '88885297328', 4, '1984-08-17');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Jasmine Dickinson II', '87195761485', 16, '1988-11-30');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Phillip Jones III', '71364383196', 19, '1965-09-07');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Benjamin Denesik', '52558753748', 3, '1986-12-17');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Bridget Steuber', '89559429911', 18, '1979-06-21');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Stewart Reinger', '29335900179', 8, '1954-06-09');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Dallas Spinka', '28938651990', 13, '1952-04-25');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Cary Dietrich', '35976507412', 19, '1985-03-19');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Viola Kuphal Jr.', '29869922671', 9, '1992-07-17');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Laurie Littel', '77598602676', 5, '1995-04-30');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Marco Waters IV', '53490199150', 2, '1981-04-27');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('May Wisozk MD', '93741009691', 12, '1965-01-04');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Flora Dickinson', '13720362016', 15, '1957-09-03');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Cecelia Grimes', '17434806765', 10, '1946-11-19');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Mamie Welch', '95828675436', 13, '2005-01-12');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Conrad Ruecker', '69218301286', 13, '1956-05-21');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Jesus Schumm', '36992522340', 13, '1949-03-15');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Cynthia Bashirian', '93405811684', 12, '1946-02-22');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Clyde OReilly', '13590644940', 15, '1946-07-16');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Josh King', '76009586388', 18, '1960-05-04');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Myron Dach', '93336817368', 20, '1963-01-06');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Madeline Pacocha', '14947211733', 1, '1990-07-01');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Dr. Mandy Torp-Schmidt', '75870523720', 19, '1957-09-16');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Taylor Brakus', '28169498024', 11, '1958-09-07');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Ellis Kozey', '90190611276', 9, '1977-01-20');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Lynn Reichel Jr.', '88259235608', 4, '2001-06-07');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Arthur Durgan', '39832793765', 12, '1986-10-26');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Josh Nolan', '63592568393', 12, '1955-12-05');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Claude Douglas', '50549657931', 4, '1974-01-09');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Cora Lang', '32063405041', 8, '1958-12-30');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Blake Farrell-Grant', '52261798006', 6, '1961-01-10');
INSERT INTO funcionario (nome, cpf, loja_id, data_nascimento) VALUES ('Ms. Kara Stiedemann', '57875954904', 20, '1944-08-09');

INSERT INTO marca (nome) VALUES ('Little, Boyle and Abshire');
INSERT INTO marca (nome) VALUES ('Rempel - Herman');
INSERT INTO marca (nome) VALUES ('Senger - Grimes');
INSERT INTO marca (nome) VALUES ('Pouros - Gutmann');
INSERT INTO marca (nome) VALUES ('Ebert Inc');
INSERT INTO marca (nome) VALUES ('Legros and Sons');
INSERT INTO marca (nome) VALUES ('Tillman - Erdman');
INSERT INTO marca (nome) VALUES ('Walter LLC');
INSERT INTO marca (nome) VALUES ('Reinger, Jakubowski and Anderson');
INSERT INTO marca (nome) VALUES ('Wiza, Hyatt and Bins');
INSERT INTO marca (nome) VALUES ('Koepp - Lubowitz');
INSERT INTO marca (nome) VALUES ('Jacobi - Veum');
INSERT INTO marca (nome) VALUES ('Heidenreich - Hammes');
INSERT INTO marca (nome) VALUES ('Crona LLC');
INSERT INTO marca (nome) VALUES ('Kuhn - Anderson');
INSERT INTO marca (nome) VALUES ('Kuvalis, Feest and Runolfsdottir');
INSERT INTO marca (nome) VALUES ('West - Koepp');
INSERT INTO marca (nome) VALUES ('Johns, Corkery and Abshire');
INSERT INTO marca (nome) VALUES ('Osinski Inc');
INSERT INTO marca (nome) VALUES ('Barton LLC');
INSERT INTO marca (nome) VALUES ('Bartoletti, Runte and Walker');
INSERT INTO marca (nome) VALUES ('Morar - Rippin');
INSERT INTO marca (nome) VALUES ('Heller, Heidenreich and Dach');
INSERT INTO marca (nome) VALUES ('Rolfson, Barton and Stoltenberg');
INSERT INTO marca (nome) VALUES ('McGlynn - Harris');
INSERT INTO marca (nome) VALUES ('Boyer Group');
INSERT INTO marca (nome) VALUES ('Hilpert, Blanda and Rolfson');
INSERT INTO marca (nome) VALUES ('Corwin, Wolf and Kutch');
INSERT INTO marca (nome) VALUES ('Jerde - Wyman');
INSERT INTO marca (nome) VALUES ('Considine - Ritchie');
INSERT INTO marca (nome) VALUES ('Pfannerstill, Rath and Becker');
INSERT INTO marca (nome) VALUES ('Conn, Harris and Ruecker');
INSERT INTO marca (nome) VALUES ('Shields Group');
INSERT INTO marca (nome) VALUES ('Schmeler, Reinger and OReilly');
INSERT INTO marca (nome) VALUES ('Stehr, Block and Bednar');
INSERT INTO marca (nome) VALUES ('Crist - Ruecker');
INSERT INTO marca (nome) VALUES ('Brakus, Emmerich and Brakus');
INSERT INTO marca (nome) VALUES ('Altenwerth, Botsford and Schmeler');
INSERT INTO marca (nome) VALUES ('Brakus - Will');
INSERT INTO marca (nome) VALUES ('Cummerata, Purdy and Roberts');

INSERT INTO produto (nome, marca_id, valor) VALUES ('Recycled Rubber Shirt', 5, 102);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Recycled Frozen Shirt', 1, 798);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Modern Bronze Cheese', 3, 945);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Modern Soft Sausages', 3, 786);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Fantastic Granite Bacon', 4, 23);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handcrafted Rubber Chips', 1, 910);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Awesome Metal Gloves', 5, 907);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Granite Shirt', 2, 319);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Electronic Fresh Soap', 5, 971);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Modern Concrete Cheese', 5, 308);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Oriental Wooden Cheese', 5, 557);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Ergonomic Granite Tuna', 1, 345);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Granite Shirt', 2, 961);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Bespoke Wooden Fish', 4, 715);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Modern Granite Chair', 1, 454);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Awesome Steel Keyboard', 2, 493);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Rustic Fresh Bacon', 1, 686);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Practical Wooden Hat', 2, 450);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Unbranded Cotton Bike', 1, 356);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Oriental Fresh Shoes', 5, 358);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Luxurious Cotton Shoes', 5, 424);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Elegant Wooden Ball', 3, 504);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Practical Rubber Computer', 1, 913);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Tasty Steel Bike', 2, 931);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Modern Steel Fish', 5, 915);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handmade Granite Pizza', 5, 508);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Licensed Cotton Pizza', 5, 899);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Cotton Mouse', 4, 674);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Incredible Concrete Mouse', 1, 182);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Recycled Rubber Gloves', 1, 76);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Unbranded Metal Chips', 3, 961);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Electronic Wooden Fish', 5, 35);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Licensed Metal Ball', 1, 819);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Elegant Frozen Pants', 5, 43);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Gorgeous Soft Fish', 4, 322);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Refined Bronze Salad', 5, 421);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Modern Wooden Chicken', 4, 449);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Modern Frozen Bike', 2, 558);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Small Rubber Car', 5, 549);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Practical Concrete Car', 5, 478);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Tasty Fresh Bike', 1, 641);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Generic Granite Salad', 4, 82);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Awesome Steel Bike', 4, 183);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Generic Fresh Cheese', 2, 550);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Incredible Steel Salad', 3, 241);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handcrafted Metal Towels', 5, 931);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Bronze Table', 2, 710);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Soft Keyboard', 3, 842);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Incredible Wooden Computer', 1, 735);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Unbranded Rubber Cheese', 5, 391);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Luxurious Wooden Pizza', 5, 446);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Tasty Fresh Sausages', 4, 153);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Tasty Steel Fish', 4, 692);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Refined Soft Computer', 2, 526);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Generic Plastic Sausages', 2, 343);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Generic Granite Pizza', 5, 483);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Practical Granite Tuna', 4, 568);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Generic Granite Chips', 5, 934);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Rustic Plastic Chips', 4, 128);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Rustic Wooden Pizza', 3, 199);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Fantastic Wooden Fish', 1, 282);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Fantastic Cotton Mouse', 5, 240);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handmade Granite Car', 5, 266);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Wooden Tuna', 3, 767);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Unbranded Cotton Soap', 2, 56);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handcrafted Cotton Sausages', 1, 883);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Oriental Metal Table', 3, 305);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Oriental Rubber Ball', 5, 716);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Elegant Wooden Hat', 3, 966);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Fantastic Steel Cheese', 2, 439);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Elegant Cotton Bike', 5, 364);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Small Concrete Computer', 4, 926);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Ergonomic Steel Chair', 3, 334);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Practical Plastic Gloves', 4, 804);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Bespoke Frozen Bike', 3, 863);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Refined Fresh Bacon', 1, 837);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Ergonomic Frozen Pizza', 1, 746);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Gorgeous Fresh Fish', 2, 904);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Unbranded Plastic Cheese', 4, 365);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handcrafted Granite Soap', 3, 125);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Incredible Plastic Cheese', 5, 62);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Licensed Metal Bike', 4, 613);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Luxurious Metal Fish', 5, 913);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Licensed Granite Chicken', 2, 488);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Generic Steel Soap', 1, 759);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handmade Cotton Cheese', 2, 821);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Incredible Bronze Fish', 2, 568);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Cotton Mouse', 2, 339);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Recycled Metal Bacon', 4, 325);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Modern Fresh Chair', 4, 56);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Bespoke Soft Chicken', 3, 855);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Practical Wooden Computer', 1, 888);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Oriental Frozen Chips', 3, 256);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Bespoke Plastic Sausages', 4, 218);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Steel Pants', 5, 728);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Licensed Soft Hat', 2, 969);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Electronic Steel Hat', 5, 293);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Practical Plastic Shoes', 5, 31);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Gorgeous Granite Bacon', 4, 517);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Bespoke Soft Towels', 4, 75);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Fantastic Plastic Ball', 2, 468);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Ergonomic Concrete Bacon', 2, 725);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Small Cotton Keyboard', 5, 141);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Fantastic Soft Tuna', 3, 727);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Practical Steel Tuna', 5, 90);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Small Metal Gloves', 2, 31);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Oriental Frozen Pizza', 1, 880);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Gorgeous Frozen Ball', 5, 857);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Incredible Frozen Car', 4, 946);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handcrafted Wooden Towels', 2, 377);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Steel Bike', 2, 482);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Modern Plastic Shoes', 2, 496);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Tasty Wooden Mouse', 2, 212);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Generic Rubber Salad', 3, 150);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Fantastic Metal Pizza', 4, 829);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Practical Metal Gloves', 4, 299);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Licensed Soft Computer', 1, 401);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Oriental Fresh Keyboard', 3, 289);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Refined Metal Keyboard', 2, 415);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Practical Fresh Keyboard', 5, 952);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Tasty Soft Bike', 3, 51);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handcrafted Concrete Sausages', 3, 671);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Recycled Wooden Fish', 3, 58);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Rubber Salad', 3, 640);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Rustic Frozen Shoes', 5, 471);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handcrafted Granite Soap', 2, 484);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Tasty Fresh Shirt', 5, 194);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Bronze Chair', 3, 103);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handmade Soft Shoes', 4, 123);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Generic Plastic Pants', 3, 460);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Oriental Concrete Bacon', 1, 528);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Wooden Pizza', 1, 512);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Unbranded Bronze Shirt', 5, 232);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Unbranded Cotton Chicken', 1, 746);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Fantastic Fresh Chips', 2, 393);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Small Soft Towels', 1, 847);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Modern Steel Cheese', 5, 111);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Practical Cotton Pants', 1, 993);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Recycled Concrete Chicken', 3, 158);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handmade Concrete Mouse', 5, 423);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Luxurious Wooden Cheese', 3, 306);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Tasty Rubber Car', 5, 200);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Generic Fresh Ball', 2, 554);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Tasty Concrete Bike', 3, 806);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Refined Rubber Sausages', 3, 295);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Practical Bronze Computer', 2, 271);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Electronic Steel Towels', 1, 43);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handmade Plastic Towels', 2, 29);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Metal Chicken', 1, 379);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Rustic Steel Hat', 4, 790);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Modern Plastic Ball', 3, 379);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handmade Frozen Chair', 2, 606);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Soft Sausages', 2, 942);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Fantastic Metal Cheese', 2, 942);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Recycled Concrete Cheese', 4, 896);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handmade Frozen Chicken', 1, 866);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Awesome Metal Salad', 5, 561);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handmade Wooden Car', 5, 250);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Elegant Granite Gloves', 4, 541);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Incredible Soft Ball', 3, 80);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handcrafted Wooden Towels', 5, 700);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Tasty Rubber Chair', 2, 415);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Granite Fish', 3, 541);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Refined Bronze Car', 5, 246);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Ergonomic Frozen Fish', 4, 189);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Incredible Frozen Soap', 1, 186);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Generic Soft Fish', 4, 83);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Ergonomic Metal Table', 5, 160);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Metal Bike', 4, 493);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Tasty Plastic Table', 2, 467);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Bespoke Rubber Soap', 5, 862);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Fantastic Concrete Bacon', 4, 274);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Soft Mouse', 3, 150);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Ergonomic Frozen Chips', 4, 172);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Bespoke Granite Fish', 3, 690);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Refined Metal Sausages', 2, 706);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Elegant Concrete Shoes', 2, 682);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Fantastic Metal Pizza', 3, 208);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Gorgeous Cotton Soap', 4, 921);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Frozen Car', 3, 376);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Awesome Bronze Computer', 3, 76);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handmade Steel Table', 1, 516);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Bespoke Rubber Keyboard', 3, 293);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Ergonomic Bronze Bike', 2, 565);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Rustic Metal Sausages', 5, 260);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Fantastic Granite Bacon', 4, 630);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Rustic Frozen Ball', 2, 181);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handmade Rubber Towels', 4, 506);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Concrete Tuna', 4, 690);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Bespoke Rubber Chair', 2, 421);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Rustic Metal Soap', 5, 610);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Tasty Cotton Car', 3, 471);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Bespoke Cotton Shoes', 2, 355);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Tasty Cotton Keyboard', 5, 571);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Handcrafted Concrete Chair', 2, 609);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Steel Chicken', 3, 281);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Ergonomic Rubber Chips', 1, 737);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Sleek Steel Computer', 2, 89);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Gorgeous Plastic Chips', 1, 185);
INSERT INTO produto (nome, marca_id, valor) VALUES ('Luxurious Bronze Tuna', 2, 113);

INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 1, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 2, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 3, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 4, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 5, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 6, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 7, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 8, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 9, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 10, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 11, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 12, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 13, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 14, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 15, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 16, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 17, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 18, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 19, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (1, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (2, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (3, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (4, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (5, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (6, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (7, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (8, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (9, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (10, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (11, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (12, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (13, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (14, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (15, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (16, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (17, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (18, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (19, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (20, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (21, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (22, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (23, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (24, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (25, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (26, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (27, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (28, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (29, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (30, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (31, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (32, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (33, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (34, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (35, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (36, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (37, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (38, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (39, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (40, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (41, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (42, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (43, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (44, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (45, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (46, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (47, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (48, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (49, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (50, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (51, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (52, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (53, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (54, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (55, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (56, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (57, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (58, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (59, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (60, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (61, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (62, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (63, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (64, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (65, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (66, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (67, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (68, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (69, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (70, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (71, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (72, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (73, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (74, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (75, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (76, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (77, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (78, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (79, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (80, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (81, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (82, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (83, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (84, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (85, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (86, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (87, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (88, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (89, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (90, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (91, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (92, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (93, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (94, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (95, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (96, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (97, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (98, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (99, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (100, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (101, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (102, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (103, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (104, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (105, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (106, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (107, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (108, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (109, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (110, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (111, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (112, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (113, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (114, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (115, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (116, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (117, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (118, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (119, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (120, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (121, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (122, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (123, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (124, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (125, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (126, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (127, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (128, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (129, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (130, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (131, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (132, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (133, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (134, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (135, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (136, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (137, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (138, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (139, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (140, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (141, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (142, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (143, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (144, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (145, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (146, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (147, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (148, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (149, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (150, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (151, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (152, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (153, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (154, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (155, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (156, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (157, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (158, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (159, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (160, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (161, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (162, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (163, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (164, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (165, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (166, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (167, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (168, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (169, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (170, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (171, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (172, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (173, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (174, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (175, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (176, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (177, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (178, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (179, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (180, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (181, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (182, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (183, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (184, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (185, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (186, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (187, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (188, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (189, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (190, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (191, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (192, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (193, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (194, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (195, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (196, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (197, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (198, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (199, 20, 10000);
INSERT INTO estoque (produto_id, loja_id, quant) VALUES (200, 20, 10000);

INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 53, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 9, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 31, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 72, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 53, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 69, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 80, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 28, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 1, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 17, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 13, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 5, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 84, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 74, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 44, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 97, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 1, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 98, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 57, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 12, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 94, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 16, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 84, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 58, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 12, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 57, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 96, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 99, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 30, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 22, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 52, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 28, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 4, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 82, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 44, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 78, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 56, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 35, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 71, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 55, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 12, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 88, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 78, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 50, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 44, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 21, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 87, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 59, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 40, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 77, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 23, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 17, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 10, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 26, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 90, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 51, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 93, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 56, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 60, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 42, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 64, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 33, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 100, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 70, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 42, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 27, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 92, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 38, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 18, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 13, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 72, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 69, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 7, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 55, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 37, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 26, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 58, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 55, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 13, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 31, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 16, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 77, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 66, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 43, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 88, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 84, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 99, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 53, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 12, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 45, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 1, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 2, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 46, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 50, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 6, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 62, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 26, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 68, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 85, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 39, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 89, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 32, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 61, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 85, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 6, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 98, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 39, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 37, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 64, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 99, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 57, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 77, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 74, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 39, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 82, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 92, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 39, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 96, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 3, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 18, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 46, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 51, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 1, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 90, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 78, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 28, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 8, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 26, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 56, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 95, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 49, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 86, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 55, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 67, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 21, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 23, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 71, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 7, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 91, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 78, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 34, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 22, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 79, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 94, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 53, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 32, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 95, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 39, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 90, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 90, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 77, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 65, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 39, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 67, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 44, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 98, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 67, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 24, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 30, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 67, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 23, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 36, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 28, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 90, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 19, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 76, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 87, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 40, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 38, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 63, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 95, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 38, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 63, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 43, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 49, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 29, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 77, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 91, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 12, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 62, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 18, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 2, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 57, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 8, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 88, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 83, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 78, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 37, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 91, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 95, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 35, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 7, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 69, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 9, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 28, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 19, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 10, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 15, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 27, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 56, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 42, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 70, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 4, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 72, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 78, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 98, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 59, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 64, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 64, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 49, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 75, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 86, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 82, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 83, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 16, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 46, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 94, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 95, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 60, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 60, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 79, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 26, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 35, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 35, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 28, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 89, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 72, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 44, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 8, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 94, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 78, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 23, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 32, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 72, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 51, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 96, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 32, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 67, 34);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 69, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 72, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 4, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 12, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 19, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 80, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 13, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 31, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 2, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 52, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 92, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 79, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 54, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 24, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 61, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 84, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 75, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 81, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 32, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 54, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 15, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 28, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 2, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 71, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 97, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 31, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 85, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 35, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 68, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 95, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 43, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 98, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 50, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 18, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 40, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 11, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 39, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 16, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 4, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 23, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 32, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 79, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 56, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 18, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 61, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 15, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 16, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 15, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 79, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 3, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 26, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 62, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 67, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 70, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 94, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 91, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 29, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 99, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 33, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 1, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 4, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 82, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 56, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 73, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 95, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 18, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 11, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 37, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 60, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 9, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 88, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 5, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 7, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 80, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 97, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 82, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 33, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 63, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 20, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 49, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 11, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 40, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 25, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 42, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 65, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 94, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 46, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 57, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 52, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 80, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 36, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 35, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 94, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 11, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 19, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 90, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 74, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 90, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 41, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 60, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 9, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 87, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 78, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 65, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 68, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 32, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 57, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 36, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 67, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 76, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 42, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 38, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 7, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 54, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 28, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 20, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 80, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 66, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 39, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 33, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 67, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 13, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 44, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 96, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 97, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 49, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 6, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 83, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 68, 34);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 5, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 4, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 80, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 24, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 17, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 20, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 12, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 5, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 32, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 11, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 38, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 29, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 46, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 89, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 73, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 30, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 85, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 89, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 38, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 87, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 39, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 12, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 42, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 45, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 71, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 30, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 100, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 62, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 45, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 19, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 3, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 19, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 79, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 47, 34);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 19, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 58, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 66, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 18, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 34, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 53, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 98, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 59, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 21, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 7, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 32, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 8, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 29, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 3, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 92, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 84, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 64, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 46, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 59, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 62, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 38, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 25, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 7, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 13, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 59, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 81, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 88, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 1, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 9, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 55, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 18, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 17, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 69, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 91, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 77, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 81, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 77, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 41, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 23, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 79, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 89, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 36, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 37, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 97, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 26, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 59, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 56, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 46, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 39, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 79, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 80, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 67, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 35, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 16, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 65, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 85, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 39, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 98, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 21, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 38, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 94, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 84, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 100, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 26, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 44, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 27, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 79, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 80, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 28, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 1, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 68, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 30, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 2, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 42, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 63, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 38, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 7, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 28, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 66, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 55, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 46, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 68, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 74, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 8, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 26, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 100, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 69, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 6, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 37, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 98, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 90, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 23, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 91, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 78, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 70, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 35, 34);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 83, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 7, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 52, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 64, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 83, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 38, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 49, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 49, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 81, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 73, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 51, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 80, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 94, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 60, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 49, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 41, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 66, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 70, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 18, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 28, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 97, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 100, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 91, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 98, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 99, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 82, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 100, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 22, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 87, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 44, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 20, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 78, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 71, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 28, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 28, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 61, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 80, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 18, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 25, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 35, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 19, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 19, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 13, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 80, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 28, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 20, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 19, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 9, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 7, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 83, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 2, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 100, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 33, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 76, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 60, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 90, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 8, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 17, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 84, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 100, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 100, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 50, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 65, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 16, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 6, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 44, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 94, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 77, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 78, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 18, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 83, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 10, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 75, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 67, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 42, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 38, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 77, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 98, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 18, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 94, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 62, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 52, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 17, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 56, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 31, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 57, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 99, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 17, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 80, 34);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 59, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 19, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 35, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 49, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 92, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 46, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 92, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 11, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 11, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 52, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 100, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 84, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 92, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 11, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 36, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 100, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 11, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 74, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 90, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 88, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 81, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 43, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 63, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 64, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 62, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 86, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 85, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 97, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 44, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 68, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 22, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 12, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 66, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 60, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 90, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 97, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 88, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 38, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 7, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 25, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 90, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 10, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 58, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 62, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 58, 34);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 89, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 66, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 14, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 81, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 97, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 81, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 10, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 4, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 32, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 58, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 63, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 89, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 84, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 59, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 54, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 32, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 97, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 94, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 34, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 94, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 64, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 4, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 62, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 96, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 55, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 78, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 31, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 63, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 95, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 62, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 30, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 67, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 96, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 31, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 92, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 75, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 84, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 41, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 6, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 49, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 41, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 19, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 34, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 3, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 63, 34);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 5, 34);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 79, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 33, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 3, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 7, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 56, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 82, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 92, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 98, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 11, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 1, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 73, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 55, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 14, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 83, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 35, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 54, 34);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 48, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 59, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 4, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 57, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 60, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 26, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 33, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 80, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 13, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 8, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 2, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 83, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 35, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 28, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 72, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 99, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 76, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 28, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 81, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 42, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 5, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 42, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 68, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 85, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 39, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 59, 9);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 93, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 30, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 92, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 98, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 69, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 22, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 24, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 92, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 70, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 23, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 23, 34);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 92, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 18, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 4, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 86, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 11, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 65, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 53, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 98, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 5, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 30, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 60, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 52, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 55, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 29, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 5, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 92, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 45, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 91, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 84, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 42, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 54, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 17, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 53, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 29, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 87, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 25, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 57, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 20, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 12, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 86, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 40, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 30, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 1, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 63, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 15, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 30, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 4, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 16, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 41, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 73, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 55, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 24, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 67, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 69, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 65, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 69, 34);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 93, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 41, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 21, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 2, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 14, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 74, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 72, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 27, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 42, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 28, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 69, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 95, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 57, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 17, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 88, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 2, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 58, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 84, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 21, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 84, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 44, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 79, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 36, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 12, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 90, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 87, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 69, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 30, 33);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 22, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 18, 45);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 48, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 3, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 60, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 50, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 40, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 97, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 41, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 57, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 20, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 64, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 24, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 19, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 88, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 88, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 90, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 40, 3);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 2, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 94, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 45, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 33, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 95, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 94, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 45, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 14, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 42, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 35, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 18, 36);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 41, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 59, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 29, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 51, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 57, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 13, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 90, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 82, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 12, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 57, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 42, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 51, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 83, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 86, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 85, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 99, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 79, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 71, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 88, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 83, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 32, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 82, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 4, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 88, 50);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 44, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 50, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 42, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 46, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 7, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 22, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 97, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 45, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 79, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 41, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 86, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 60, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 78, 2);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 15, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 87, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 9, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 71, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 27, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 10, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 57, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 81, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 67, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 87, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 15, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 4, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 4, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 97, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 64, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 37, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 50, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 21, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 10, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 84, 27);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 7, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 44, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 39, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 10, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 81, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 41, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 69, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 72, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 38, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 100, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 54, 39);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 5, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 28, 43);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 21, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 19, 25);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 80, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 81, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 60, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 36, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 62, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 30, 20);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 37, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 26, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 83, 37);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 76, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 59, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 51, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 41, 42);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 38, 7);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 22, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 96, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 9, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 30, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 34, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 18, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 26, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 18, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 1, 47);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 29, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 29, 46);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 15, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 5, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 17, 17);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 72, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 67, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 43, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 25, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 69, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 54, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 43, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 13, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 26, 34);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 48, 19);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 55, 31);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 52, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 64, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 33, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 21, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 62, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 1, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 7, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 69, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 8, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (2, 63, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 57, 38);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 73, 1);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 43, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 2, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 20, 23);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 87, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 56, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 94, 14);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 55, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 95, 5);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 79, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 49, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 31, 35);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 95, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 17, 26);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 1, 10);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 7, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 38, 8);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 23, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 57, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 94, 15);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 52, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 49, 41);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 44, 49);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 91, 13);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 29, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 36, 6);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 23, 40);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 36, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 12, 12);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 8, 32);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 52, 21);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 34, 48);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (5, 49, 34);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (3, 20, 11);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 67, 29);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (9, 66, 16);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (7, 5, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 82, 4);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 42, 30);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (8, 36, 24);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 96, 22);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (1, 41, 18);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (6, 44, 28);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (10, 24, 44);
INSERT INTO venda (loja_id, cliente_id, funcionario_id) VALUES (4, 90, 48);

INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (1, 46, 8, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (1, 189, 3, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (1, 20, 3, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (1, 100, 4, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (1, 52, 1, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (2, 126, 9, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (2, 6, 1, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (2, 4, 7, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (3, 1, 10, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (3, 25, 2, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (3, 89, 2, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (3, 114, 8, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (4, 163, 3, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (4, 186, 1, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (4, 16, 8, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (4, 77, 8, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (4, 6, 8, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (4, 182, 10, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (5, 135, 6, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (5, 89, 1, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (5, 42, 2, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (6, 173, 9, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (6, 164, 3, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (6, 108, 7, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (6, 76, 8, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (6, 157, 6, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (7, 178, 7, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (7, 15, 6, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (7, 66, 9, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (7, 168, 5, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (7, 169, 3, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (7, 192, 8, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (8, 58, 2, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (8, 160, 6, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (8, 71, 2, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (8, 99, 8, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (8, 156, 1, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (8, 121, 9, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (8, 135, 6, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (9, 190, 1, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (9, 189, 8, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (9, 60, 9, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (9, 7, 7, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (10, 107, 6, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (10, 162, 8, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (10, 17, 7, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (10, 84, 8, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (11, 59, 9, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (11, 38, 9, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (11, 95, 4, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (12, 152, 10, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (12, 188, 1, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (12, 173, 2, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (13, 138, 6, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (13, 187, 3, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (13, 133, 4, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (13, 57, 8, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (13, 123, 5, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (13, 134, 4, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (13, 89, 7, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (14, 25, 7, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (14, 33, 7, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (14, 104, 5, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (14, 199, 6, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (15, 15, 6, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (16, 48, 9, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (16, 173, 4, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (16, 85, 10, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (16, 155, 1, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (16, 128, 4, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (16, 103, 8, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (16, 134, 9, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (17, 54, 3, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (17, 99, 8, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (17, 4, 1, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (17, 121, 6, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (17, 2, 3, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (18, 141, 4, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (18, 13, 4, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (18, 196, 7, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (19, 151, 3, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (19, 143, 4, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (19, 93, 10, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (19, 195, 7, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (19, 98, 7, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (19, 17, 2, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (19, 76, 8, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (19, 88, 2, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (20, 180, 10, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (20, 52, 4, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (20, 99, 5, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (20, 26, 4, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (21, 143, 9, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (21, 182, 5, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (21, 4, 10, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (21, 19, 5, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (21, 138, 7, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (21, 188, 2, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (21, 97, 4, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (21, 185, 7, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (22, 99, 10, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (22, 91, 9, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (22, 85, 7, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (22, 20, 6, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (22, 138, 9, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (22, 46, 3, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (23, 74, 9, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (23, 189, 8, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (23, 187, 10, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (23, 93, 2, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (23, 150, 10, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (23, 61, 7, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (23, 171, 3, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (24, 103, 6, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (24, 6, 8, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (24, 33, 3, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (24, 137, 4, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (24, 144, 8, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (24, 54, 4, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (24, 21, 2, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (24, 190, 10, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (25, 151, 7, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (25, 159, 4, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (25, 72, 3, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (25, 30, 2, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (25, 181, 6, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (25, 109, 8, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (26, 103, 3, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (26, 32, 10, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (26, 95, 3, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (26, 83, 6, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (27, 41, 2, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (27, 17, 10, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (28, 100, 4, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (29, 25, 7, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (29, 26, 6, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (30, 153, 1, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (30, 44, 2, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (30, 98, 10, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (30, 65, 9, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (30, 122, 9, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (30, 22, 1, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (30, 28, 5, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (31, 113, 4, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (31, 175, 10, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (31, 189, 2, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (31, 79, 1, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (31, 190, 3, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (31, 196, 5, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (32, 189, 4, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (32, 160, 7, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (32, 26, 8, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (32, 200, 9, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (32, 148, 8, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (32, 140, 8, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (32, 60, 10, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (32, 120, 10, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (33, 34, 9, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (33, 49, 9, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (33, 175, 6, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (33, 83, 10, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (34, 109, 9, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (34, 36, 9, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (34, 131, 9, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (34, 106, 5, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (34, 24, 3, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (34, 191, 5, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (35, 153, 1, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (35, 125, 3, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (36, 17, 3, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (36, 195, 4, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (36, 4, 5, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (37, 72, 3, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (37, 114, 7, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (37, 126, 9, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (37, 82, 4, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (37, 108, 7, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (37, 19, 2, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (38, 4, 7, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (38, 134, 2, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (38, 32, 6, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (38, 132, 4, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (38, 63, 6, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (38, 116, 4, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (38, 23, 5, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (38, 22, 7, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (39, 5, 2, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (39, 160, 9, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (40, 62, 8, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (40, 2, 4, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (40, 1, 1, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (40, 188, 9, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (41, 42, 5, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (41, 172, 6, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (41, 162, 8, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (41, 64, 3, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (41, 45, 8, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (41, 159, 3, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (42, 128, 1, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (42, 61, 9, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (42, 133, 9, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (43, 101, 7, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (43, 158, 4, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (43, 54, 8, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (43, 40, 5, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (43, 161, 8, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (44, 165, 10, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (44, 100, 7, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (44, 25, 8, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (44, 173, 4, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (45, 58, 2, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (45, 147, 10, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (45, 83, 8, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (45, 19, 7, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (45, 101, 8, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (45, 149, 3, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (45, 66, 3, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (45, 186, 6, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (46, 15, 7, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (46, 40, 7, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (46, 155, 8, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (46, 80, 6, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (46, 58, 5, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (46, 7, 6, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (46, 69, 6, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (46, 38, 8, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (47, 107, 7, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (47, 115, 3, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (47, 198, 6, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (47, 95, 5, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (48, 18, 4, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (49, 174, 9, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (49, 184, 10, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (49, 91, 8, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (49, 109, 4, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (50, 121, 3, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (50, 18, 8, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (51, 28, 8, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (51, 142, 10, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (52, 19, 3, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (52, 105, 5, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (52, 185, 3, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (52, 79, 6, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (52, 127, 3, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (52, 75, 1, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (52, 53, 3, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (53, 33, 8, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (53, 74, 2, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (53, 189, 6, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (54, 2, 2, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (54, 133, 8, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (54, 29, 6, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (54, 20, 9, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (54, 57, 9, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (54, 196, 5, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (54, 58, 10, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (55, 131, 2, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (55, 53, 10, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (56, 5, 7, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (56, 124, 5, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (56, 140, 8, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (56, 116, 9, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (56, 176, 3, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (56, 43, 3, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (57, 52, 1, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (58, 139, 4, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (58, 121, 5, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (59, 150, 6, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (59, 33, 10, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (59, 188, 5, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (60, 173, 2, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (60, 45, 6, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (60, 114, 2, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (60, 136, 1, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (60, 130, 1, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (60, 104, 4, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (60, 64, 5, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (61, 19, 2, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (61, 153, 10, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (61, 195, 2, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (62, 186, 4, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (62, 102, 10, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (62, 7, 10, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (62, 5, 8, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (63, 194, 4, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (63, 91, 3, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (64, 88, 10, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (64, 199, 3, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (64, 196, 1, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (64, 62, 8, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (64, 195, 8, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (65, 45, 6, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (65, 40, 1, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (65, 116, 6, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (65, 37, 4, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (66, 85, 8, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (66, 141, 4, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (67, 22, 6, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (67, 195, 4, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (67, 64, 9, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (67, 55, 5, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (68, 128, 2, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (68, 64, 5, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (68, 160, 1, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (69, 157, 3, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (69, 61, 7, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (70, 136, 9, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (70, 110, 2, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (70, 96, 7, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (70, 181, 10, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (70, 154, 4, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (71, 105, 3, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (71, 69, 10, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (71, 19, 2, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (71, 65, 5, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (71, 66, 5, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (71, 58, 3, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (72, 50, 5, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (72, 112, 3, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (72, 174, 9, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (72, 40, 2, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (72, 188, 5, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (73, 7, 3, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (73, 36, 5, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (73, 77, 7, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (73, 113, 4, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (73, 151, 7, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (73, 142, 4, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (73, 109, 4, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (74, 141, 10, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (74, 11, 6, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (75, 187, 9, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (75, 163, 4, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (75, 118, 2, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (75, 171, 7, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (75, 45, 7, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (75, 101, 8, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (76, 106, 9, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (77, 103, 2, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (78, 104, 7, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (79, 190, 7, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (79, 165, 7, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (79, 90, 4, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (79, 168, 7, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (79, 122, 9, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (79, 73, 6, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (79, 125, 2, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (79, 107, 3, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (80, 61, 2, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (80, 200, 9, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (80, 58, 10, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (80, 170, 2, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (80, 139, 1, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (81, 139, 9, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (81, 189, 2, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (81, 49, 5, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (81, 145, 4, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (81, 78, 10, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (82, 70, 7, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (82, 162, 10, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (82, 10, 1, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (82, 18, 1, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (83, 126, 7, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (83, 155, 8, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (83, 69, 5, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (83, 49, 5, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (84, 124, 8, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (84, 146, 2, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (84, 27, 8, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (85, 98, 7, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (85, 84, 5, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (85, 159, 6, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (85, 59, 9, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (85, 191, 9, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (85, 57, 7, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (86, 84, 4, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (86, 197, 9, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (86, 170, 8, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (87, 5, 8, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (87, 19, 10, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (87, 23, 5, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (87, 180, 4, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (87, 100, 6, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (87, 67, 8, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (87, 96, 3, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (88, 37, 2, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (88, 183, 4, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (88, 127, 7, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (88, 47, 2, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (88, 57, 1, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (89, 50, 10, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (89, 47, 7, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (89, 108, 8, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (89, 174, 8, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (89, 82, 7, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (89, 2, 9, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (89, 142, 1, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (90, 7, 3, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (90, 132, 4, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (90, 42, 4, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (90, 139, 3, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (90, 48, 8, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (90, 66, 4, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (90, 116, 7, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (90, 44, 1, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (91, 49, 7, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (91, 131, 6, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (91, 29, 4, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (92, 181, 4, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (92, 10, 4, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (92, 76, 1, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (92, 77, 7, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (92, 13, 2, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (93, 42, 9, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (93, 108, 2, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (93, 191, 8, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (94, 107, 10, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (94, 96, 5, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (95, 53, 4, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (95, 54, 9, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (96, 184, 10, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (97, 27, 3, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (97, 188, 6, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (97, 86, 2, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (97, 179, 8, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (97, 106, 2, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (98, 1, 10, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (98, 2, 6, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (98, 137, 3, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (98, 35, 2, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (98, 131, 10, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (98, 183, 6, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (98, 93, 9, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (99, 156, 8, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (99, 179, 7, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (99, 103, 9, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (99, 146, 3, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (100, 91, 8, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (100, 33, 7, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (100, 59, 1, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (100, 200, 4, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (100, 189, 7, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (100, 95, 2, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (100, 88, 8, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (100, 187, 8, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (101, 1, 9, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (101, 186, 6, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (101, 198, 2, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (101, 108, 10, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (101, 92, 5, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (101, 116, 4, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (102, 99, 3, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (103, 88, 10, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (103, 42, 9, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (103, 48, 7, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (104, 57, 5, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (104, 7, 3, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (104, 37, 8, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (104, 123, 8, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (104, 19, 4, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (104, 63, 10, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (104, 177, 4, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (105, 149, 10, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (105, 57, 2, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (105, 55, 5, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (106, 55, 10, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (106, 42, 2, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (106, 135, 4, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (107, 53, 9, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (107, 118, 5, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (107, 178, 6, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (107, 39, 1, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (108, 157, 10, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (108, 133, 3, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (108, 174, 7, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (109, 78, 7, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (110, 16, 7, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (110, 109, 7, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (110, 3, 10, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (110, 74, 7, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (110, 83, 9, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (110, 37, 2, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (111, 58, 10, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (111, 185, 8, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (111, 47, 6, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (112, 129, 2, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (112, 82, 2, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (112, 56, 3, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (112, 196, 6, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (113, 16, 9, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (113, 196, 10, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (113, 190, 9, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (114, 144, 9, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (114, 90, 9, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (114, 164, 5, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (114, 180, 8, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (115, 176, 1, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (115, 131, 7, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (115, 117, 2, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (115, 76, 3, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (115, 133, 7, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (115, 185, 9, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (115, 64, 7, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (116, 18, 10, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (116, 113, 3, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (117, 168, 6, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (117, 20, 5, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (117, 133, 5, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (118, 149, 10, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (118, 76, 4, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (118, 80, 9, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (118, 179, 2, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (118, 32, 2, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (119, 197, 5, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (119, 65, 6, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (119, 115, 6, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (119, 133, 3, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (119, 59, 3, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (119, 70, 3, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (120, 154, 5, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (120, 20, 1, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (120, 98, 8, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (120, 157, 10, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (120, 54, 1, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (121, 102, 1, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (121, 52, 4, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (121, 176, 6, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (122, 188, 7, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (122, 13, 7, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (122, 115, 9, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (122, 65, 3, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (122, 36, 9, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (122, 158, 1, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (122, 185, 8, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (123, 67, 2, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (123, 60, 1, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (123, 85, 1, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (123, 94, 3, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (123, 80, 9, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (123, 135, 4, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (123, 179, 7, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (123, 113, 3, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (124, 170, 7, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (124, 76, 10, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (124, 70, 10, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (124, 173, 9, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (124, 2, 4, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (124, 10, 6, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (125, 97, 3, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (125, 181, 3, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (125, 82, 4, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (125, 193, 7, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (126, 13, 6, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (127, 148, 10, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (127, 158, 6, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (127, 130, 5, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (128, 120, 10, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (128, 157, 2, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (128, 140, 3, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (129, 6, 7, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (129, 28, 3, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (129, 13, 8, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (130, 192, 10, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (130, 3, 3, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (130, 161, 8, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (130, 27, 9, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (130, 147, 1, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (130, 150, 1, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (130, 21, 8, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (131, 90, 5, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (131, 69, 9, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (131, 15, 5, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (131, 3, 1, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (131, 55, 4, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (131, 24, 3, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (132, 178, 9, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (132, 43, 7, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (132, 14, 7, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (132, 11, 1, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (132, 67, 3, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (133, 38, 2, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (133, 51, 4, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (133, 107, 2, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (133, 77, 3, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (134, 17, 8, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (134, 50, 3, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (134, 99, 9, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (134, 103, 4, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (134, 164, 6, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (134, 139, 6, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (135, 181, 1, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (135, 185, 7, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (135, 53, 4, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (135, 26, 9, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (135, 170, 8, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (135, 5, 6, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (136, 121, 4, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (136, 102, 5, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (136, 76, 10, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (136, 97, 2, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (136, 174, 3, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (137, 43, 7, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (138, 159, 6, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (138, 175, 7, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (138, 128, 8, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (139, 158, 2, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (139, 159, 6, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (139, 129, 4, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (139, 17, 3, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (140, 185, 6, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (140, 168, 3, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (141, 95, 3, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (141, 99, 3, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (141, 38, 4, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (141, 53, 7, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (141, 106, 6, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (141, 107, 7, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (141, 54, 1, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (142, 189, 6, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (142, 110, 2, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (142, 90, 3, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (142, 29, 9, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (142, 171, 9, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (142, 168, 5, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (143, 29, 5, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (143, 89, 10, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (143, 116, 6, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (143, 22, 8, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (144, 91, 6, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (144, 13, 4, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (144, 56, 3, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (145, 160, 6, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (145, 172, 10, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (146, 56, 3, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (146, 154, 6, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (146, 64, 9, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (146, 168, 4, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (146, 120, 7, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (147, 69, 3, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (147, 96, 5, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (147, 4, 2, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (148, 71, 2, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (148, 122, 1, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (149, 1, 5, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (149, 56, 9, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (149, 64, 10, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (149, 72, 6, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (149, 51, 5, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (149, 179, 9, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (150, 65, 6, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (150, 48, 1, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (151, 121, 8, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (151, 73, 1, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (151, 132, 5, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (152, 39, 1, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (152, 175, 4, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (152, 48, 8, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (152, 12, 10, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (152, 140, 2, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (153, 155, 4, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (153, 73, 2, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (153, 54, 6, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (153, 118, 3, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (153, 40, 3, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (153, 94, 8, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (153, 62, 10, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (154, 152, 9, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (154, 165, 6, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (154, 128, 10, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (155, 73, 10, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (155, 85, 1, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (155, 148, 2, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (155, 55, 4, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (155, 139, 2, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (155, 176, 3, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (155, 117, 1, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (156, 174, 6, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (157, 122, 4, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (158, 138, 5, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (159, 11, 8, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (159, 58, 6, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (160, 46, 9, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (160, 53, 10, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (160, 118, 10, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (160, 123, 1, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (160, 164, 9, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (161, 136, 10, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (161, 74, 6, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (161, 188, 5, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (161, 44, 4, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (162, 52, 5, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (162, 54, 1, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (162, 45, 2, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (162, 51, 10, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (162, 134, 2, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (163, 170, 8, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (163, 163, 6, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (163, 60, 10, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (163, 180, 3, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (163, 100, 6, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (164, 78, 1, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (164, 94, 6, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (164, 41, 1, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (164, 33, 4, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (164, 199, 2, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (164, 177, 3, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (164, 196, 6, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (165, 154, 2, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (166, 83, 10, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (166, 48, 6, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (166, 19, 7, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (166, 123, 2, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (166, 45, 1, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (166, 57, 9, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (167, 134, 1, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (167, 108, 8, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (167, 47, 7, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (167, 43, 7, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (167, 101, 1, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (168, 182, 10, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (168, 5, 3, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (168, 71, 2, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (168, 116, 8, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (168, 118, 8, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (168, 187, 3, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (169, 11, 4, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (169, 182, 8, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (169, 56, 3, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (170, 88, 8, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (170, 110, 10, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (170, 79, 8, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (170, 28, 1, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (171, 155, 7, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (171, 19, 9, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (171, 16, 7, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (171, 84, 4, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (171, 4, 10, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (171, 66, 6, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (171, 3, 4, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (171, 118, 10, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (172, 199, 1, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (172, 8, 6, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (172, 167, 9, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (172, 175, 8, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (172, 177, 10, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (172, 114, 1, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (172, 55, 4, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (173, 76, 5, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (174, 178, 5, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (174, 67, 8, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (174, 51, 9, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (175, 45, 3, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (175, 179, 1, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (175, 175, 1, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (175, 126, 10, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (175, 12, 1, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (176, 29, 8, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (176, 101, 8, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (176, 137, 7, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (176, 129, 8, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (176, 23, 4, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (176, 192, 4, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (177, 192, 7, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (177, 35, 1, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (178, 73, 5, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (178, 147, 2, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (178, 37, 4, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (178, 92, 10, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (178, 11, 5, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (179, 79, 9, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (179, 168, 7, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (179, 108, 1, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (179, 55, 6, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (180, 187, 5, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (180, 143, 2, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (180, 121, 10, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (180, 148, 10, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (181, 193, 1, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (181, 16, 6, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (181, 140, 5, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (181, 119, 2, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (181, 63, 9, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (181, 104, 1, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (182, 97, 5, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (182, 181, 7, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (182, 40, 6, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (182, 1, 2, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (183, 105, 4, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (183, 117, 8, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (183, 80, 4, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (183, 104, 6, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (183, 85, 10, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (183, 70, 3, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (183, 177, 7, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (183, 140, 3, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (184, 158, 2, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (184, 119, 10, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (184, 56, 3, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (184, 37, 7, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (185, 1, 9, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (185, 109, 2, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (185, 75, 4, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (185, 35, 1, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (185, 105, 9, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (185, 176, 10, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (185, 83, 6, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (185, 26, 3, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (186, 151, 6, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (186, 17, 6, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (187, 18, 10, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (187, 184, 1, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (187, 16, 8, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (187, 188, 2, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (187, 15, 5, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (187, 72, 1, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (187, 117, 9, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (188, 150, 6, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (188, 93, 2, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (188, 118, 10, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (188, 68, 9, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (189, 24, 6, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (189, 168, 9, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (189, 164, 3, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (189, 121, 4, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (189, 41, 3, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (189, 143, 10, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (189, 55, 8, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (190, 34, 10, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (190, 100, 8, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (191, 181, 10, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (191, 50, 2, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (191, 54, 4, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (191, 102, 9, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (191, 36, 7, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (191, 21, 10, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (191, 159, 1, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (192, 115, 6, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (192, 19, 7, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (192, 109, 1, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (192, 21, 9, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (192, 30, 7, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (192, 108, 3, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (192, 92, 9, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (192, 182, 1, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (193, 18, 5, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (193, 4, 1, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (193, 30, 5, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (193, 56, 9, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (193, 195, 6, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (193, 142, 3, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (193, 1, 4, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (193, 8, 8, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (194, 191, 7, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (194, 108, 10, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (194, 69, 10, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (194, 193, 1, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (194, 106, 1, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (195, 187, 1, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (195, 175, 9, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (195, 22, 5, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (195, 52, 2, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (195, 4, 3, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (196, 105, 3, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (196, 133, 10, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (196, 61, 10, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (197, 165, 6, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (197, 57, 7, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (197, 74, 8, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (197, 109, 4, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (197, 199, 3, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (198, 113, 2, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (198, 25, 1, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (198, 121, 8, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (198, 130, 9, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (198, 199, 4, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (198, 105, 2, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (198, 71, 6, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (199, 136, 2, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (199, 106, 10, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (199, 43, 9, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (199, 55, 1, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (199, 177, 7, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (199, 23, 1, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (199, 22, 1, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (199, 4, 9, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (200, 150, 6, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (200, 79, 1, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (200, 102, 3, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (201, 95, 3, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (201, 150, 4, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (201, 4, 9, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (201, 63, 1, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (201, 39, 8, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (201, 71, 7, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (201, 183, 10, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (202, 26, 6, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (202, 29, 1, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (202, 60, 1, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (202, 143, 6, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (202, 79, 8, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (202, 168, 1, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (202, 169, 7, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (203, 144, 5, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (203, 114, 10, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (203, 194, 4, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (203, 4, 10, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (203, 149, 6, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (203, 85, 10, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (203, 193, 6, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (204, 63, 7, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (204, 73, 5, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (204, 154, 10, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (204, 83, 9, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (204, 8, 6, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (204, 6, 7, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (204, 29, 5, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (205, 42, 1, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (205, 12, 6, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (206, 132, 10, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (206, 174, 1, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (206, 150, 6, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (206, 106, 1, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (206, 10, 10, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (207, 86, 7, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (207, 3, 3, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (207, 66, 2, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (207, 21, 5, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (207, 119, 10, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (208, 151, 10, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (208, 135, 4, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (209, 56, 6, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (209, 196, 3, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (209, 59, 2, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (209, 42, 5, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (209, 124, 7, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (209, 22, 9, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (209, 36, 2, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (209, 175, 8, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (210, 19, 4, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (210, 160, 6, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (210, 20, 1, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (210, 71, 4, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (210, 73, 7, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (211, 171, 5, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (211, 59, 7, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (211, 26, 9, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (211, 65, 9, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (211, 16, 7, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (211, 154, 1, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (212, 109, 10, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (212, 101, 10, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (212, 14, 4, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (212, 105, 5, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (212, 16, 10, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (213, 74, 1, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (213, 36, 3, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (213, 120, 2, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (213, 195, 6, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (214, 117, 7, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (214, 134, 9, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (214, 140, 6, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (214, 116, 7, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (215, 166, 2, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (215, 114, 10, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (215, 69, 7, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (215, 130, 4, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (216, 96, 10, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (216, 67, 9, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (217, 3, 6, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (217, 189, 7, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (217, 87, 10, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (217, 66, 6, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (217, 23, 7, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (218, 33, 10, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (218, 85, 3, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (218, 36, 3, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (218, 171, 2, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (219, 182, 10, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (220, 62, 10, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (220, 97, 9, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (220, 164, 9, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (220, 31, 3, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (220, 82, 5, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (220, 135, 10, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (220, 121, 9, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (220, 40, 4, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (221, 168, 10, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (221, 10, 6, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (221, 138, 7, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (221, 72, 6, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (221, 165, 5, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (221, 127, 2, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (221, 89, 9, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (221, 133, 8, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (222, 61, 2, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (222, 78, 9, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (222, 176, 4, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (222, 42, 1, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (223, 140, 2, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (223, 181, 4, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (223, 59, 3, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (224, 165, 9, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (224, 141, 9, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (224, 130, 5, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (224, 32, 1, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (224, 27, 10, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (224, 86, 8, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (224, 177, 4, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (225, 170, 7, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (225, 186, 2, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (226, 56, 1, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (226, 142, 10, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (226, 189, 6, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (226, 14, 8, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (226, 175, 3, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (226, 67, 3, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (226, 187, 1, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (226, 153, 6, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (227, 51, 8, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (228, 197, 10, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (228, 164, 2, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (228, 162, 2, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (228, 107, 5, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (229, 183, 4, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (230, 40, 4, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (231, 2, 6, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (231, 128, 3, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (231, 18, 8, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (231, 170, 8, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (231, 41, 2, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (231, 194, 3, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (231, 139, 1, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (231, 162, 8, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (232, 84, 9, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (232, 95, 6, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (232, 32, 1, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (232, 81, 10, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (232, 10, 8, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (232, 129, 5, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (232, 103, 6, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (232, 183, 1, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (233, 79, 4, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (233, 60, 3, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (233, 48, 8, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (233, 153, 7, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (233, 59, 9, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (234, 179, 4, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (234, 16, 7, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (234, 172, 8, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (235, 2, 1, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (235, 113, 4, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (235, 159, 3, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (235, 54, 4, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (236, 192, 2, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (236, 168, 1, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (236, 130, 6, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (236, 120, 9, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (236, 129, 1, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (236, 151, 7, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (236, 144, 8, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (237, 141, 9, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (238, 45, 4, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (238, 96, 4, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (238, 37, 5, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (238, 183, 6, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (239, 119, 6, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (239, 128, 1, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (239, 10, 1, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (239, 120, 1, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (239, 30, 9, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (239, 97, 6, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (239, 137, 7, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (240, 41, 10, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (240, 13, 2, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (240, 127, 2, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (240, 119, 1, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (240, 6, 1, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (240, 3, 4, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (241, 134, 4, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (241, 198, 2, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (241, 199, 3, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (241, 65, 9, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (242, 77, 1, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (242, 33, 5, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (242, 148, 8, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (242, 106, 2, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (242, 184, 2, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (243, 153, 1, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (243, 121, 5, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (244, 34, 10, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (244, 81, 10, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (244, 129, 4, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (244, 149, 10, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (244, 199, 6, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (244, 82, 6, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (244, 48, 3, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (244, 136, 5, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (245, 48, 10, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (245, 56, 10, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (245, 83, 7, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (245, 19, 1, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (245, 192, 9, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (246, 183, 3, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (246, 14, 1, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (246, 101, 2, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (246, 7, 7, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (247, 112, 6, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (247, 39, 2, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (247, 139, 1, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (247, 47, 9, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (247, 151, 6, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (248, 167, 10, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (248, 45, 4, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (248, 146, 6, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (248, 13, 6, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (248, 61, 3, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (249, 56, 3, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (249, 82, 5, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (249, 42, 8, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (249, 50, 4, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (249, 39, 2, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (249, 60, 4, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (249, 108, 3, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (249, 88, 7, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (250, 170, 8, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (251, 153, 9, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (251, 57, 1, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (251, 182, 1, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (252, 15, 4, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (252, 48, 4, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (252, 50, 3, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (252, 38, 10, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (252, 139, 4, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (252, 20, 10, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (253, 170, 2, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (253, 115, 8, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (253, 46, 10, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (253, 43, 10, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (253, 128, 5, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (253, 178, 4, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (254, 162, 8, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (254, 81, 7, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (254, 73, 4, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (254, 14, 6, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (255, 92, 7, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (255, 102, 1, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (255, 39, 1, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (255, 163, 4, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (256, 148, 5, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (256, 116, 3, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (256, 30, 2, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (256, 188, 7, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (256, 171, 9, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (256, 27, 10, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (257, 129, 2, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (257, 126, 9, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (257, 175, 7, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (257, 134, 4, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (257, 39, 5, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (258, 125, 3, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (259, 46, 10, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (259, 147, 8, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (259, 80, 3, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (259, 193, 9, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (260, 62, 9, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (261, 89, 4, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (261, 17, 3, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (261, 192, 5, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (262, 198, 5, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (262, 71, 2, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (262, 129, 2, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (263, 196, 9, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (263, 71, 1, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (263, 48, 1, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (263, 176, 8, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (263, 58, 4, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (263, 187, 8, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (264, 174, 4, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (264, 149, 8, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (264, 75, 5, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (264, 78, 1, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (264, 2, 2, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (264, 27, 1, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (265, 143, 10, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (265, 172, 5, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (265, 152, 4, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (265, 141, 4, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (265, 99, 8, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (265, 63, 7, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (266, 36, 10, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (266, 17, 5, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (266, 184, 10, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (267, 198, 6, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (267, 25, 4, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (267, 188, 10, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (267, 97, 9, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (267, 117, 6, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (267, 190, 5, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (267, 107, 6, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (268, 38, 10, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (268, 129, 5, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (268, 71, 6, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (268, 115, 6, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (268, 196, 8, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (268, 133, 7, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (268, 82, 9, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (268, 88, 6, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (269, 131, 8, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (269, 45, 9, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (269, 85, 5, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (269, 147, 5, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (269, 138, 4, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (269, 36, 7, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (269, 111, 8, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (269, 42, 8, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (270, 200, 9, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (271, 70, 1, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (271, 10, 7, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (271, 3, 3, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (271, 29, 5, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (272, 198, 9, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (272, 73, 8, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (272, 146, 9, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (272, 62, 1, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (272, 136, 8, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (273, 63, 1, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (273, 22, 3, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (273, 186, 2, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (273, 155, 2, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (273, 118, 1, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (274, 144, 10, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (274, 183, 6, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (274, 23, 10, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (275, 65, 6, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (275, 68, 7, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (275, 14, 5, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (275, 90, 7, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (275, 129, 10, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (275, 29, 9, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (275, 120, 5, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (276, 131, 8, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (276, 139, 9, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (277, 61, 3, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (277, 86, 3, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (277, 28, 1, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (277, 198, 2, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (278, 31, 2, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (278, 165, 7, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (278, 57, 8, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (278, 189, 10, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (278, 148, 10, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (278, 192, 10, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (278, 84, 7, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (279, 122, 6, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (279, 24, 9, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (279, 77, 4, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (279, 40, 5, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (279, 56, 7, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (280, 47, 4, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (280, 187, 1, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (280, 22, 3, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (280, 139, 5, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (280, 151, 6, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (280, 152, 8, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (280, 175, 2, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (281, 128, 4, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (281, 183, 1, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (281, 38, 5, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (282, 9, 9, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (283, 150, 7, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (283, 128, 8, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (283, 4, 6, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (283, 5, 7, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (283, 130, 10, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (283, 161, 3, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (284, 153, 7, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (284, 59, 3, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (284, 23, 9, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (284, 51, 7, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (284, 186, 1, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (284, 108, 7, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (285, 48, 1, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (285, 1, 10, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (285, 91, 4, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (285, 36, 7, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (285, 44, 4, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (285, 106, 6, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (286, 6, 10, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (286, 35, 4, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (286, 193, 8, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (287, 132, 6, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (287, 58, 8, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (288, 176, 2, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (288, 23, 6, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (288, 132, 2, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (288, 126, 7, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (288, 93, 9, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (288, 182, 4, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (288, 154, 8, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (288, 6, 4, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (289, 25, 10, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (289, 84, 2, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (289, 117, 6, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (289, 74, 7, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (289, 159, 6, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (290, 13, 6, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (290, 151, 7, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (290, 164, 9, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (290, 41, 4, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (290, 200, 10, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (290, 187, 6, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (290, 131, 2, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (290, 160, 5, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (291, 79, 9, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (291, 20, 1, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (291, 64, 8, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (291, 29, 8, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (292, 67, 6, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (292, 124, 10, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (292, 98, 2, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (293, 3, 3, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (293, 1, 4, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (293, 172, 1, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (293, 130, 7, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (293, 16, 8, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (293, 68, 5, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (293, 17, 9, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (294, 11, 5, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (294, 124, 9, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (294, 37, 10, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (294, 150, 5, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (294, 51, 10, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (295, 24, 8, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (295, 193, 1, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (295, 118, 3, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (295, 89, 7, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (296, 77, 1, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (296, 159, 4, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (296, 162, 3, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (296, 20, 2, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (296, 2, 3, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (296, 9, 1, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (297, 24, 5, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (297, 3, 5, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (297, 81, 1, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (297, 10, 7, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (297, 128, 3, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (297, 30, 9, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (297, 121, 3, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (298, 121, 5, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (298, 5, 8, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (298, 118, 3, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (299, 129, 7, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (299, 20, 6, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (299, 63, 10, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (300, 151, 8, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (300, 99, 3, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (300, 34, 6, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (300, 140, 1, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (300, 147, 10, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (300, 66, 9, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (301, 115, 2, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (301, 196, 6, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (301, 154, 1, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (301, 48, 3, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (301, 161, 3, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (301, 142, 1, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (301, 55, 3, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (302, 133, 4, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (303, 15, 4, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (303, 84, 9, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (304, 101, 1, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (305, 122, 1, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (305, 166, 4, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (305, 197, 10, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (305, 179, 6, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (305, 4, 3, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (305, 156, 9, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (305, 76, 2, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (306, 135, 2, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (307, 7, 6, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (307, 76, 4, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (307, 198, 10, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (307, 45, 5, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (307, 17, 3, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (307, 21, 4, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (308, 93, 5, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (308, 63, 10, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (308, 182, 9, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (308, 69, 2, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (308, 52, 5, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (309, 126, 6, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (309, 123, 3, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (309, 197, 9, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (309, 115, 4, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (309, 63, 2, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (309, 68, 8, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (310, 7, 7, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (310, 51, 10, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (310, 160, 6, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (310, 37, 8, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (310, 45, 5, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (310, 182, 7, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (311, 62, 5, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (311, 103, 2, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (311, 106, 1, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (312, 105, 1, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (313, 154, 10, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (313, 9, 7, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (313, 50, 5, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (313, 170, 7, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (313, 98, 5, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (314, 148, 4, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (314, 170, 1, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (314, 130, 2, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (315, 40, 5, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (316, 116, 9, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (316, 124, 1, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (316, 181, 10, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (316, 112, 1, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (316, 77, 5, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (317, 191, 2, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (318, 96, 1, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (318, 164, 5, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (318, 138, 2, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (318, 73, 10, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (318, 4, 9, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (318, 157, 5, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (319, 83, 1, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (320, 86, 8, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (320, 176, 3, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (320, 153, 4, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (320, 50, 3, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (320, 106, 7, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (321, 114, 3, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (321, 4, 4, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (321, 77, 5, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (321, 32, 10, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (321, 14, 8, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (321, 20, 2, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (321, 72, 2, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (321, 195, 4, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (322, 171, 6, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (322, 21, 1, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (322, 99, 7, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (322, 50, 6, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (322, 43, 4, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (322, 68, 7, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (322, 139, 4, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (323, 8, 2, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (323, 184, 10, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (323, 138, 3, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (323, 26, 6, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (323, 191, 3, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (323, 66, 9, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (324, 178, 6, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (324, 181, 2, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (324, 56, 3, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (324, 90, 7, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (324, 52, 9, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (325, 12, 5, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (325, 24, 7, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (326, 40, 8, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (326, 188, 7, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (326, 17, 2, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (326, 124, 2, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (326, 163, 5, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (326, 177, 10, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (326, 100, 6, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (326, 106, 5, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (327, 71, 1, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (327, 107, 4, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (327, 95, 1, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (327, 150, 2, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (328, 77, 3, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (328, 72, 6, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (328, 93, 1, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (329, 183, 5, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (329, 110, 10, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (330, 97, 10, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (330, 44, 3, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (331, 113, 8, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (331, 197, 3, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (331, 77, 7, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (331, 4, 8, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (332, 183, 3, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (332, 140, 10, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (332, 95, 2, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (332, 87, 6, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (332, 179, 6, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (332, 26, 2, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (332, 187, 2, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (333, 122, 3, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (333, 52, 8, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (333, 14, 2, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (333, 131, 10, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (333, 117, 6, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (333, 191, 9, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (334, 11, 9, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (334, 113, 7, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (334, 100, 10, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (335, 31, 8, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (335, 38, 1, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (335, 63, 3, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (335, 165, 8, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (335, 106, 7, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (336, 52, 9, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (336, 122, 5, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (336, 94, 3, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (336, 33, 2, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (336, 74, 4, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (336, 164, 3, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (336, 174, 5, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (337, 12, 5, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (337, 107, 4, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (337, 63, 5, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (337, 54, 7, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (337, 100, 1, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (337, 28, 3, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (337, 73, 6, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (338, 192, 4, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (338, 174, 6, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (338, 134, 7, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (339, 72, 7, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (339, 66, 7, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (339, 165, 7, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (339, 76, 1, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (339, 189, 7, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (340, 171, 6, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (340, 91, 2, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (341, 23, 4, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (341, 12, 4, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (341, 35, 8, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (341, 50, 3, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (341, 174, 10, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (341, 135, 10, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (341, 199, 9, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (341, 115, 7, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (342, 45, 4, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (342, 187, 10, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (342, 139, 2, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (342, 58, 9, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (342, 174, 9, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (342, 11, 6, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (342, 38, 8, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (342, 119, 10, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (343, 198, 7, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (343, 130, 3, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (343, 33, 6, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (344, 51, 7, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (345, 23, 2, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (345, 59, 6, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (345, 139, 7, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (345, 196, 3, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (345, 164, 8, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (345, 67, 8, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (346, 195, 9, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (346, 78, 1, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (346, 74, 1, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (346, 41, 3, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (347, 112, 4, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (347, 169, 3, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (347, 101, 5, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (347, 13, 3, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (348, 123, 7, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (348, 62, 8, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (348, 138, 8, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (349, 13, 8, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (349, 67, 10, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (349, 115, 2, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (349, 140, 9, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (349, 184, 1, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (349, 3, 10, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (349, 33, 2, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (350, 188, 1, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (350, 48, 5, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (351, 101, 8, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (351, 11, 3, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (351, 158, 2, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (352, 125, 3, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (352, 169, 10, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (352, 51, 8, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (352, 114, 8, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (353, 55, 3, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (354, 103, 5, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (354, 165, 6, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (354, 49, 2, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (354, 135, 1, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (355, 198, 10, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (355, 33, 9, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (355, 70, 8, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (355, 74, 5, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (356, 89, 9, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (356, 98, 8, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (357, 172, 9, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (358, 182, 10, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (358, 199, 10, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (358, 175, 2, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (358, 98, 5, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (359, 180, 9, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (359, 61, 1, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (359, 174, 10, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (359, 19, 3, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (359, 199, 4, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (359, 117, 5, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (360, 129, 8, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (360, 72, 5, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (360, 148, 2, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (360, 179, 8, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (360, 185, 4, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (360, 117, 1, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (361, 63, 8, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (361, 122, 7, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (361, 43, 6, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (361, 173, 1, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (362, 22, 1, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (362, 93, 2, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (362, 190, 2, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (363, 49, 1, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (363, 79, 9, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (363, 142, 3, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (364, 49, 6, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (364, 194, 6, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (365, 73, 6, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (365, 29, 10, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (365, 115, 8, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (365, 194, 1, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (366, 132, 10, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (366, 28, 9, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (366, 145, 7, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (366, 187, 10, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (366, 109, 9, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (366, 93, 2, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (366, 103, 2, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (366, 52, 5, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (367, 75, 9, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (367, 73, 7, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (367, 7, 10, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (367, 133, 10, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (367, 164, 10, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (367, 172, 6, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (368, 152, 5, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (368, 148, 2, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (368, 33, 1, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (368, 107, 6, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (368, 43, 6, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (368, 122, 3, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (368, 172, 2, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (368, 3, 3, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (369, 141, 1, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (370, 62, 6, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (370, 59, 8, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (370, 5, 7, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (370, 175, 6, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (371, 146, 3, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (371, 83, 9, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (372, 94, 3, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (372, 171, 8, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (372, 163, 2, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (373, 44, 9, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (373, 97, 6, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (373, 198, 6, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (373, 121, 10, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (373, 70, 2, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (373, 107, 4, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (374, 18, 7, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (374, 143, 8, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (374, 181, 1, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (374, 8, 5, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (375, 24, 1, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (375, 175, 10, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (375, 140, 7, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (375, 97, 5, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (376, 31, 2, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (376, 87, 9, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (376, 4, 10, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (377, 63, 9, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (377, 164, 3, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (377, 105, 2, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (377, 192, 10, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (377, 124, 4, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (377, 67, 3, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (378, 50, 4, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (378, 193, 5, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (378, 157, 7, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (378, 105, 4, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (379, 131, 2, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (379, 35, 7, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (379, 185, 6, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (379, 22, 3, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (379, 33, 3, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (379, 199, 2, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (379, 121, 5, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (380, 29, 8, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (380, 16, 4, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (380, 143, 7, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (380, 10, 1, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (380, 31, 8, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (381, 199, 6, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (381, 95, 5, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (381, 123, 8, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (382, 200, 3, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (382, 27, 1, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (382, 187, 7, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (382, 18, 7, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (382, 158, 6, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (382, 88, 5, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (383, 140, 7, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (383, 29, 3, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (383, 64, 10, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (383, 190, 9, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (383, 1, 2, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (384, 192, 1, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (385, 25, 7, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (385, 165, 9, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (385, 184, 1, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (385, 19, 4, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (385, 43, 3, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (385, 14, 3, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (385, 2, 10, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (385, 87, 10, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (386, 50, 1, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (386, 17, 1, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (386, 191, 10, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (386, 81, 7, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (387, 160, 10, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (387, 196, 5, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (387, 47, 8, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (387, 8, 3, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (387, 148, 8, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (388, 184, 1, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (388, 169, 10, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (388, 200, 1, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (388, 5, 1, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (388, 141, 10, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (388, 54, 10, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (388, 167, 2, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (388, 162, 5, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (389, 56, 5, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (389, 42, 8, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (389, 180, 10, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (390, 13, 8, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (390, 200, 1, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (390, 24, 9, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (390, 138, 9, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (391, 125, 4, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (391, 151, 9, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (391, 169, 2, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (391, 142, 8, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (391, 23, 7, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (392, 190, 9, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (392, 27, 8, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (392, 188, 3, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (392, 161, 6, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (392, 78, 10, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (393, 26, 2, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (393, 185, 1, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (393, 197, 9, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (393, 77, 6, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (393, 41, 7, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (393, 10, 3, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (393, 198, 4, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (393, 158, 1, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (394, 174, 5, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (394, 131, 6, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (394, 69, 2, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (394, 159, 9, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (394, 148, 7, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (395, 10, 4, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (395, 194, 4, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (395, 128, 6, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (395, 116, 2, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (396, 87, 6, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (396, 155, 8, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (396, 108, 10, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (396, 16, 5, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (396, 41, 8, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (397, 44, 2, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (397, 89, 4, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (397, 80, 3, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (397, 46, 6, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (398, 23, 4, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (399, 66, 3, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (399, 88, 4, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (399, 155, 9, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (399, 103, 10, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (399, 123, 3, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (399, 182, 7, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (400, 74, 2, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (401, 40, 5, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (401, 198, 4, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (401, 26, 8, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (401, 88, 2, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (401, 165, 7, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (402, 47, 10, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (402, 173, 7, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (402, 167, 6, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (403, 53, 6, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (403, 23, 10, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (403, 25, 2, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (404, 121, 6, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (404, 28, 1, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (404, 151, 8, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (404, 5, 4, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (404, 75, 2, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (404, 157, 7, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (405, 108, 2, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (405, 40, 1, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (405, 198, 1, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (405, 196, 5, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (406, 79, 10, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (406, 151, 2, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (407, 46, 9, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (407, 92, 6, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (407, 56, 3, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (407, 61, 9, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (407, 113, 3, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (407, 146, 9, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (407, 192, 4, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (408, 56, 4, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (408, 40, 6, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (408, 46, 9, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (408, 13, 4, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (408, 22, 6, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (408, 143, 4, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (408, 107, 4, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (409, 96, 10, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (409, 115, 6, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (409, 82, 9, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (409, 22, 4, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (409, 143, 3, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (409, 176, 7, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (409, 53, 6, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (410, 109, 4, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (410, 112, 2, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (410, 14, 4, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (410, 106, 5, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (410, 66, 6, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (410, 49, 9, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (411, 170, 5, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (411, 28, 9, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (411, 191, 7, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (411, 20, 5, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (411, 34, 10, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (411, 123, 6, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (412, 112, 8, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (412, 171, 6, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (412, 71, 1, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (412, 198, 5, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (412, 29, 9, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (412, 52, 4, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (412, 186, 1, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (413, 80, 4, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (414, 111, 3, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (415, 18, 5, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (415, 52, 4, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (415, 101, 4, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (416, 140, 10, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (416, 125, 10, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (417, 117, 5, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (417, 127, 6, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (417, 180, 10, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (417, 102, 8, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (417, 193, 8, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (417, 126, 3, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (418, 153, 5, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (418, 34, 3, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (418, 76, 10, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (418, 184, 1, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (418, 198, 1, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (419, 32, 3, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (419, 81, 4, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (420, 117, 9, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (420, 148, 1, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (420, 35, 9, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (421, 199, 1, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (421, 54, 7, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (421, 144, 9, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (421, 47, 6, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (421, 95, 1, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (421, 127, 5, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (421, 1, 9, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (422, 59, 10, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (422, 18, 5, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (422, 171, 10, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (422, 56, 5, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (422, 95, 3, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (422, 197, 7, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (422, 103, 9, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (423, 105, 6, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (423, 89, 3, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (423, 50, 2, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (423, 23, 10, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (423, 193, 9, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (423, 116, 3, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (423, 33, 7, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (423, 187, 8, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (424, 121, 10, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (424, 167, 10, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (424, 66, 7, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (424, 181, 8, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (425, 194, 8, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (425, 54, 6, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (425, 24, 2, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (425, 85, 6, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (425, 31, 4, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (426, 138, 4, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (426, 11, 4, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (426, 105, 9, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (426, 67, 2, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (426, 49, 3, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (426, 17, 8, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (426, 78, 4, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (427, 19, 5, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (427, 182, 3, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (427, 43, 9, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (427, 29, 10, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (427, 157, 4, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (427, 30, 1, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (427, 88, 4, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (427, 77, 3, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (428, 8, 7, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (428, 82, 5, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (428, 172, 1, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (429, 144, 1, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (429, 84, 8, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (429, 79, 7, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (430, 124, 5, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (430, 50, 8, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (430, 144, 3, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (430, 149, 7, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (430, 176, 8, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (430, 115, 9, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (430, 33, 7, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (431, 145, 8, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (431, 72, 9, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (431, 153, 8, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (431, 31, 2, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (431, 163, 4, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (431, 102, 1, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (432, 133, 7, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (432, 66, 4, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (432, 57, 2, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (432, 27, 2, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (432, 187, 7, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (432, 35, 10, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (432, 41, 7, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (433, 81, 8, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (434, 27, 9, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (435, 184, 1, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (435, 46, 9, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (435, 134, 7, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (435, 110, 5, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (435, 5, 4, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (435, 91, 7, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (435, 114, 8, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (436, 118, 4, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (436, 124, 4, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (436, 117, 5, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (436, 129, 9, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (437, 126, 7, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (437, 79, 9, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (437, 5, 9, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (437, 154, 5, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (437, 10, 7, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (438, 132, 7, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (438, 35, 4, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (438, 170, 1, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (438, 158, 2, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (438, 8, 5, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (438, 49, 7, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (438, 125, 2, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (439, 174, 2, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (439, 187, 2, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (439, 50, 5, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (439, 130, 6, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (439, 156, 6, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (439, 198, 10, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (439, 168, 2, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (440, 152, 3, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (440, 117, 9, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (440, 140, 5, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (440, 97, 1, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (440, 130, 8, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (440, 198, 2, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (441, 112, 7, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (441, 132, 10, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (441, 37, 6, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (442, 62, 2, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (443, 185, 7, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (443, 30, 9, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (443, 42, 2, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (443, 158, 6, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (443, 37, 8, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (443, 137, 6, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (444, 43, 7, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (444, 178, 7, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (444, 7, 9, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (444, 38, 7, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (444, 98, 6, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (444, 151, 8, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (444, 160, 10, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (445, 54, 6, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (445, 176, 1, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (445, 71, 9, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (445, 185, 6, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (445, 63, 8, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (446, 41, 5, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (446, 160, 10, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (446, 70, 7, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (446, 150, 4, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (446, 165, 5, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (446, 101, 6, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (447, 25, 6, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (447, 32, 2, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (447, 82, 1, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (447, 155, 4, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (447, 195, 1, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (448, 50, 2, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (448, 145, 9, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (448, 126, 8, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (448, 60, 4, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (448, 62, 8, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (448, 172, 8, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (448, 49, 9, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (449, 48, 7, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (449, 170, 8, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (449, 65, 1, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (449, 29, 6, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (450, 159, 4, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (450, 22, 5, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (450, 127, 8, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (450, 39, 10, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (451, 141, 2, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (451, 200, 10, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (451, 133, 6, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (451, 136, 4, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (451, 128, 2, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (451, 37, 6, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (452, 56, 10, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (452, 98, 8, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (452, 147, 5, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (453, 15, 3, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (453, 19, 2, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (453, 118, 8, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (453, 131, 3, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (453, 49, 7, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (453, 86, 10, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (454, 148, 10, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (454, 39, 8, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (454, 100, 7, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (454, 144, 5, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (455, 103, 9, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (456, 185, 1, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (456, 4, 9, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (457, 116, 10, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (457, 39, 10, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (458, 167, 9, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (458, 109, 9, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (458, 116, 9, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (458, 153, 5, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (459, 34, 6, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (459, 152, 2, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (460, 20, 5, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (460, 71, 10, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (461, 169, 4, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (461, 119, 10, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (461, 173, 5, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (461, 81, 9, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (461, 181, 10, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (461, 157, 9, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (462, 37, 6, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (462, 105, 10, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (463, 110, 2, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (463, 193, 5, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (463, 3, 10, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (464, 102, 2, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (464, 200, 8, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (464, 173, 3, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (464, 9, 1, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (465, 147, 1, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (465, 59, 3, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (465, 3, 5, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (465, 165, 5, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (465, 4, 10, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (465, 14, 6, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (466, 25, 8, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (466, 171, 9, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (466, 30, 1, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (466, 132, 5, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (467, 162, 6, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (467, 17, 7, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (467, 8, 6, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (467, 128, 6, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (467, 85, 4, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (467, 19, 10, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (467, 127, 8, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (468, 108, 2, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (468, 86, 9, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (469, 176, 7, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (470, 136, 7, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (470, 156, 6, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (470, 94, 5, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (470, 193, 8, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (470, 18, 4, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (470, 77, 4, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (471, 57, 3, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (472, 46, 1, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (472, 153, 7, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (472, 148, 3, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (472, 169, 7, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (472, 178, 10, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (473, 11, 1, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (473, 162, 1, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (473, 125, 6, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (473, 143, 5, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (474, 138, 10, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (474, 51, 8, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (474, 126, 7, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (474, 166, 3, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (474, 162, 2, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (474, 1, 9, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (474, 114, 6, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (475, 69, 5, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (475, 38, 3, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (476, 147, 2, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (476, 14, 5, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (476, 52, 2, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (476, 60, 4, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (476, 62, 5, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (476, 116, 3, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (476, 200, 10, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (477, 115, 8, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (478, 118, 1, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (479, 147, 10, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (479, 99, 10, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (479, 174, 5, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (480, 67, 5, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (481, 50, 6, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (481, 70, 2, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (481, 87, 5, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (481, 88, 3, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (481, 120, 6, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (481, 60, 5, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (481, 59, 5, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (481, 110, 3, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (482, 77, 5, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (482, 58, 8, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (482, 6, 5, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (482, 190, 1, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (483, 73, 1, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (483, 32, 7, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (483, 28, 3, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (483, 13, 3, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (483, 53, 6, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (484, 142, 9, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (484, 28, 9, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (484, 113, 6, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (484, 36, 6, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (484, 138, 5, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (484, 12, 9, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (484, 87, 1, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (484, 139, 7, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (485, 196, 10, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (485, 161, 7, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (486, 53, 5, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (486, 5, 5, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (486, 141, 2, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (486, 80, 7, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (486, 65, 9, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (487, 20, 1, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (487, 99, 9, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (488, 130, 9, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (488, 60, 4, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (488, 55, 3, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (488, 163, 4, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (489, 135, 6, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (489, 186, 3, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (489, 181, 1, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (489, 34, 5, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (490, 81, 6, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (490, 59, 8, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (490, 122, 10, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (490, 67, 2, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (490, 156, 10, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (490, 80, 10, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (491, 188, 5, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (491, 37, 7, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (491, 199, 8, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (491, 12, 3, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (491, 151, 3, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (491, 117, 3, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (491, 178, 10, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (491, 70, 10, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (492, 1, 8, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (493, 48, 10, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (493, 193, 1, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (493, 20, 5, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (494, 181, 6, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (494, 145, 8, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (494, 104, 5, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (494, 69, 8, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (494, 111, 6, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (494, 125, 4, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (494, 44, 10, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (494, 88, 8, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (495, 159, 5, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (495, 188, 7, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (495, 170, 9, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (496, 12, 4, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (496, 117, 3, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (496, 15, 10, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (496, 59, 2, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (496, 178, 2, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (496, 4, 10, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (497, 173, 10, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (497, 144, 3, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (498, 88, 9, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (498, 198, 1, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (498, 122, 9, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (498, 116, 5, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (499, 121, 3, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (499, 111, 1, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (499, 153, 1, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (499, 21, 10, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (499, 154, 10, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (500, 137, 1, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (500, 89, 2, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (500, 40, 8, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (501, 197, 9, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (501, 100, 10, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (501, 138, 8, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (501, 115, 8, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (501, 195, 6, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (501, 52, 9, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (502, 126, 2, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (502, 143, 7, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (502, 161, 8, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (502, 64, 4, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (502, 38, 8, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (502, 142, 6, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (502, 51, 2, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (503, 158, 4, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (503, 89, 10, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (503, 26, 7, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (503, 189, 5, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (503, 42, 1, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (503, 174, 10, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (503, 59, 1, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (503, 4, 10, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (504, 70, 7, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (504, 163, 8, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (504, 149, 9, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (505, 94, 7, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (505, 66, 1, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (505, 12, 4, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (505, 138, 10, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (505, 181, 2, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (505, 130, 9, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (505, 171, 7, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (506, 121, 4, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (506, 162, 1, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (506, 41, 8, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (507, 164, 9, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (507, 109, 1, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (507, 182, 3, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (507, 189, 6, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (507, 186, 7, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (507, 5, 1, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (507, 71, 1, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (508, 96, 9, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (508, 128, 3, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (508, 110, 4, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (508, 57, 9, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (509, 103, 2, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (509, 188, 10, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (509, 176, 2, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (509, 131, 1, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (509, 87, 2, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (509, 110, 5, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (509, 126, 4, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (510, 11, 3, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (510, 68, 8, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (511, 192, 7, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (511, 108, 8, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (511, 152, 2, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (512, 57, 6, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (512, 114, 7, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (512, 179, 6, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (512, 172, 3, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (512, 43, 9, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (513, 61, 2, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (513, 98, 8, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (513, 136, 8, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (513, 102, 2, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (513, 86, 3, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (513, 165, 8, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (513, 23, 3, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (513, 189, 9, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (514, 34, 7, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (515, 149, 4, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (515, 47, 6, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (515, 95, 5, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (516, 44, 5, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (516, 10, 3, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (516, 97, 1, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (517, 92, 3, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (517, 166, 7, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (517, 46, 5, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (517, 94, 5, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (518, 107, 3, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (518, 134, 3, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (518, 6, 5, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (518, 17, 5, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (518, 109, 8, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (518, 12, 5, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (518, 48, 4, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (518, 133, 7, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (519, 59, 9, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (519, 63, 3, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (519, 65, 7, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (520, 54, 8, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (521, 69, 2, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (521, 141, 10, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (521, 24, 3, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (521, 40, 2, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (521, 190, 3, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (522, 58, 6, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (522, 100, 1, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (522, 198, 3, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (523, 195, 1, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (523, 45, 5, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (523, 104, 8, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (523, 8, 7, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (523, 61, 1, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (523, 103, 7, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (523, 96, 5, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (524, 73, 9, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (524, 38, 4, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (525, 70, 5, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (525, 96, 2, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (526, 143, 4, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (526, 77, 8, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (526, 151, 3, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (526, 66, 3, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (526, 166, 8, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (526, 200, 6, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (527, 164, 9, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (527, 143, 6, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (527, 154, 3, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (528, 25, 6, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (528, 180, 1, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (528, 188, 3, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (528, 47, 1, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (528, 19, 6, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (528, 4, 1, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (528, 7, 3, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (528, 195, 7, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (529, 167, 5, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (529, 36, 4, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (529, 189, 5, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (530, 195, 6, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (530, 143, 3, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (530, 56, 8, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (531, 122, 9, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (531, 78, 5, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (531, 184, 8, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (531, 166, 6, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (531, 106, 7, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (531, 14, 8, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (532, 159, 3, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (532, 69, 5, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (532, 105, 3, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (532, 92, 7, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (533, 53, 4, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (533, 193, 7, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (534, 127, 3, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (534, 78, 2, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (534, 52, 9, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (535, 84, 9, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (535, 181, 9, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (535, 3, 5, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (535, 41, 10, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (535, 172, 10, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (535, 18, 9, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (535, 195, 1, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (536, 188, 1, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (536, 43, 1, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (536, 32, 4, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (536, 62, 5, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (536, 96, 6, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (536, 85, 8, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (536, 68, 7, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (537, 200, 8, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (537, 168, 10, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (537, 13, 10, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (537, 22, 2, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (537, 153, 8, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (537, 169, 8, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (537, 23, 4, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (537, 52, 1, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (538, 134, 10, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (538, 183, 5, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (538, 161, 5, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (539, 46, 10, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (539, 114, 3, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (539, 91, 1, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (539, 120, 1, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (539, 29, 2, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (539, 16, 2, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (540, 142, 2, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (540, 178, 7, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (540, 164, 6, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (541, 5, 10, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (542, 164, 7, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (542, 142, 1, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (542, 173, 4, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (542, 128, 10, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (542, 60, 7, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (542, 11, 5, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (542, 124, 5, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (543, 16, 4, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (543, 155, 5, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (543, 8, 7, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (543, 38, 6, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (543, 158, 6, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (543, 92, 10, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (543, 56, 8, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (544, 114, 1, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (544, 178, 4, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (544, 65, 7, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (545, 155, 1, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (546, 160, 2, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (546, 170, 8, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (546, 126, 2, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (546, 152, 2, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (546, 98, 10, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (546, 113, 9, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (546, 17, 5, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (547, 123, 5, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (547, 199, 7, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (547, 159, 5, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (547, 132, 8, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (548, 84, 2, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (548, 62, 4, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (548, 185, 8, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (549, 78, 5, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (549, 143, 4, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (549, 163, 9, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (549, 189, 10, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (549, 53, 1, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (549, 75, 6, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (550, 184, 10, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (551, 178, 5, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (552, 65, 2, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (553, 77, 1, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (553, 144, 6, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (553, 54, 5, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (553, 52, 8, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (553, 195, 5, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (553, 13, 7, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (553, 46, 9, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (553, 104, 3, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (554, 95, 8, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (554, 13, 10, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (554, 123, 8, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (554, 111, 2, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (555, 63, 9, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (555, 114, 6, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (555, 156, 7, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (555, 39, 1, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (555, 103, 8, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (556, 23, 10, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (556, 85, 4, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (556, 35, 8, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (556, 177, 2, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (556, 182, 9, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (557, 184, 3, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (558, 92, 6, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (558, 169, 7, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (558, 32, 2, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (559, 83, 3, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (559, 101, 5, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (559, 77, 7, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (559, 150, 6, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (559, 160, 9, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (559, 115, 2, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (559, 176, 4, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (560, 196, 6, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (560, 52, 9, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (560, 169, 4, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (560, 55, 8, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (560, 137, 8, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (560, 165, 1, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (561, 136, 9, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (561, 199, 8, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (561, 132, 10, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (561, 17, 4, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (561, 89, 10, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (561, 107, 7, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (561, 189, 1, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (562, 159, 6, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (562, 51, 1, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (562, 38, 2, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (563, 96, 6, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (563, 170, 4, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (563, 129, 4, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (563, 156, 6, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (563, 112, 2, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (563, 99, 5, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (564, 172, 8, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (564, 100, 6, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (564, 1, 2, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (564, 174, 2, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (564, 155, 9, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (565, 92, 5, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (565, 11, 6, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (565, 139, 4, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (565, 132, 9, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (565, 94, 10, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (565, 8, 6, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (566, 117, 3, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (566, 2, 6, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (566, 52, 5, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (566, 135, 2, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (566, 85, 9, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (566, 90, 3, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (567, 77, 4, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (567, 169, 5, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (567, 102, 8, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (567, 168, 4, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (567, 194, 10, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (568, 59, 3, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (568, 194, 5, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (568, 138, 10, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (568, 130, 9, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (568, 51, 6, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (569, 42, 3, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (569, 61, 9, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (569, 16, 8, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (569, 34, 8, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (569, 4, 7, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (570, 122, 4, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (571, 127, 10, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (571, 67, 8, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (571, 96, 2, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (571, 198, 10, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (571, 4, 5, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (571, 108, 5, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (572, 13, 5, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (572, 161, 9, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (572, 81, 6, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (572, 194, 10, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (572, 179, 4, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (572, 45, 9, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (573, 98, 3, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (574, 124, 10, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (574, 78, 10, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (574, 79, 2, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (575, 49, 5, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (576, 111, 10, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (576, 122, 9, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (576, 159, 10, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (577, 4, 10, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (577, 168, 3, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (577, 60, 9, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (577, 84, 6, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (577, 142, 7, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (577, 1, 1, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (578, 159, 2, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (578, 13, 9, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (578, 10, 3, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (578, 72, 4, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (578, 91, 1, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (579, 173, 2, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (579, 191, 2, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (579, 89, 6, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (580, 182, 8, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (580, 164, 9, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (580, 193, 6, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (581, 23, 5, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (581, 112, 9, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (581, 152, 8, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (581, 124, 10, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (581, 48, 10, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (581, 180, 1, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (581, 138, 10, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (581, 120, 7, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (582, 119, 6, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (582, 76, 1, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (582, 5, 6, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (582, 195, 3, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (583, 18, 4, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (583, 26, 2, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (583, 162, 7, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (583, 19, 3, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (583, 121, 5, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (583, 8, 3, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (584, 23, 4, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (584, 64, 10, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (584, 174, 8, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (584, 82, 4, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (584, 70, 5, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (584, 66, 5, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (584, 63, 5, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (585, 71, 1, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (586, 162, 1, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (587, 156, 4, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (587, 186, 4, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (587, 104, 7, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (587, 39, 9, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (588, 199, 1, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (588, 58, 7, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (588, 176, 9, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (588, 134, 6, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (589, 41, 5, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (589, 110, 7, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (589, 200, 9, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (589, 129, 6, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (589, 184, 5, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (589, 71, 6, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (589, 138, 8, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (589, 173, 7, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (590, 185, 2, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (590, 92, 7, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (590, 88, 4, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (590, 122, 8, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (590, 45, 2, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (590, 161, 4, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (590, 187, 9, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (590, 42, 1, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (591, 8, 6, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (591, 38, 9, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (591, 65, 8, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (591, 183, 4, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (591, 61, 3, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (591, 3, 7, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (591, 48, 9, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (592, 12, 5, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (593, 99, 7, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (593, 171, 1, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (593, 47, 2, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (593, 134, 10, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (593, 49, 8, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (593, 45, 3, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (593, 87, 2, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (594, 155, 6, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (594, 102, 4, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (594, 98, 4, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (594, 19, 4, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (594, 50, 10, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (594, 59, 3, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (594, 156, 1, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (595, 90, 5, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (595, 174, 4, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (595, 30, 3, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (596, 32, 9, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (597, 175, 7, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (597, 186, 6, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (597, 111, 6, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (597, 151, 4, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (597, 126, 5, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (597, 83, 3, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (597, 138, 1, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (598, 18, 3, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (598, 107, 8, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (598, 62, 6, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (598, 12, 8, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (598, 2, 2, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (598, 188, 5, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (598, 65, 10, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (599, 27, 9, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (599, 53, 6, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (600, 89, 9, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (600, 149, 9, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (600, 2, 5, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (600, 86, 1, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (600, 143, 8, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (600, 41, 1, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (601, 64, 6, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (601, 55, 5, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (601, 87, 9, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (601, 42, 3, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (601, 98, 2, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (602, 199, 4, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (602, 176, 4, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (602, 164, 1, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (602, 140, 7, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (602, 30, 10, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (602, 119, 9, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (602, 121, 3, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (603, 61, 2, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (603, 195, 2, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (603, 124, 6, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (603, 95, 3, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (604, 97, 8, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (604, 43, 6, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (604, 122, 4, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (604, 76, 9, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (604, 22, 6, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (604, 153, 2, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (605, 183, 3, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (605, 122, 9, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (606, 154, 2, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (606, 161, 9, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (606, 139, 4, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (606, 88, 5, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (606, 132, 3, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (607, 130, 5, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (607, 76, 10, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (607, 16, 2, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (608, 155, 7, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (608, 31, 3, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (608, 91, 6, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (608, 6, 5, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (608, 132, 1, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (608, 149, 6, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (608, 2, 7, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (608, 140, 7, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (609, 144, 1, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (609, 32, 1, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (609, 48, 9, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (609, 53, 3, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (610, 71, 6, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (610, 99, 4, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (611, 51, 10, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (611, 152, 2, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (611, 148, 5, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (611, 39, 9, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (611, 11, 9, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (611, 166, 1, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (612, 157, 5, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (612, 145, 1, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (612, 58, 7, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (612, 133, 5, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (612, 198, 8, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (612, 67, 5, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (613, 143, 6, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (613, 117, 5, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (613, 107, 3, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (613, 150, 7, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (613, 50, 1, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (614, 87, 5, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (614, 125, 9, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (614, 83, 1, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (615, 160, 3, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (616, 129, 10, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (616, 11, 7, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (616, 19, 3, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (616, 142, 10, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (616, 53, 6, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (616, 184, 6, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (617, 168, 10, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (617, 6, 6, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (618, 119, 3, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (618, 155, 4, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (618, 1, 8, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (618, 83, 9, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (618, 14, 8, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (619, 14, 7, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (619, 135, 6, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (620, 146, 10, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (621, 116, 2, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (621, 68, 4, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (621, 72, 7, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (621, 83, 5, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (621, 18, 8, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (621, 188, 3, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (622, 21, 8, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (622, 187, 3, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (622, 194, 2, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (622, 53, 6, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (623, 63, 6, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (623, 49, 1, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (623, 18, 8, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (623, 199, 10, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (623, 141, 10, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (623, 36, 9, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (624, 127, 7, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (624, 167, 8, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (624, 105, 1, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (625, 149, 7, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (625, 183, 5, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (625, 161, 10, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (625, 140, 5, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (625, 71, 9, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (625, 55, 2, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (625, 20, 7, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (625, 78, 5, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (626, 2, 10, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (626, 89, 2, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (626, 200, 9, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (626, 79, 4, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (627, 32, 9, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (627, 189, 2, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (627, 142, 1, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (628, 157, 4, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (628, 184, 9, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (629, 97, 10, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (629, 132, 7, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (629, 25, 2, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (630, 85, 3, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (630, 19, 2, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (630, 164, 4, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (631, 140, 10, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (631, 104, 5, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (631, 185, 8, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (631, 50, 4, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (631, 89, 5, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (631, 167, 2, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (631, 158, 3, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (632, 129, 5, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (633, 60, 6, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (633, 120, 7, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (633, 196, 10, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (633, 138, 10, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (633, 46, 9, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (633, 101, 5, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (633, 17, 10, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (634, 116, 6, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (634, 13, 8, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (634, 33, 1, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (634, 156, 8, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (634, 85, 4, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (634, 44, 2, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (634, 38, 5, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (635, 115, 1, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (635, 161, 1, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (635, 9, 2, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (636, 126, 8, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (636, 179, 7, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (636, 148, 10, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (636, 122, 5, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (636, 9, 5, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (636, 51, 9, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (637, 101, 3, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (637, 129, 7, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (638, 6, 3, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (638, 7, 5, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (638, 152, 9, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (638, 47, 9, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (638, 42, 9, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (638, 183, 8, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (639, 20, 8, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (639, 55, 5, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (639, 11, 6, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (639, 162, 8, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (639, 35, 6, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (640, 25, 1, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (640, 188, 4, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (640, 187, 1, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (640, 76, 1, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (640, 17, 7, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (640, 54, 6, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (640, 166, 10, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (640, 73, 1, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (641, 157, 7, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (641, 148, 10, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (642, 14, 1, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (642, 88, 10, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (642, 33, 2, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (642, 100, 7, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (643, 124, 7, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (643, 172, 1, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (644, 161, 8, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (644, 49, 7, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (644, 165, 1, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (644, 197, 9, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (644, 195, 7, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (644, 78, 5, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (645, 130, 1, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (645, 41, 1, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (645, 159, 8, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (645, 66, 10, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (645, 123, 9, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (645, 147, 8, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (646, 87, 4, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (646, 53, 5, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (646, 71, 8, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (646, 132, 7, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (646, 60, 1, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (646, 185, 6, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (646, 17, 2, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (647, 38, 1, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (647, 116, 10, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (647, 165, 2, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (647, 134, 6, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (647, 148, 8, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (647, 41, 3, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (648, 154, 7, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (648, 117, 7, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (648, 100, 8, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (648, 164, 9, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (648, 176, 10, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (649, 40, 6, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (650, 158, 6, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (650, 181, 9, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (650, 87, 8, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (650, 121, 1, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (650, 110, 1, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (651, 21, 3, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (652, 21, 5, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (652, 151, 1, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (652, 87, 3, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (652, 38, 2, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (652, 187, 7, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (652, 150, 10, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (653, 107, 7, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (653, 183, 5, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (653, 125, 7, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (653, 134, 1, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (653, 4, 2, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (653, 83, 3, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (653, 5, 7, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (653, 76, 8, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (654, 54, 6, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (654, 154, 5, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (654, 100, 8, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (654, 63, 2, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (654, 177, 7, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (654, 33, 1, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (654, 24, 10, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (655, 69, 7, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (655, 143, 1, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (655, 127, 1, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (655, 31, 6, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (655, 85, 4, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (655, 50, 9, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (655, 26, 1, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (656, 141, 10, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (656, 56, 2, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (656, 178, 1, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (656, 164, 3, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (657, 38, 9, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (658, 177, 9, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (658, 29, 1, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (658, 10, 9, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (659, 140, 5, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (659, 57, 4, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (659, 174, 6, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (659, 136, 1, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (659, 163, 1, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (659, 26, 8, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (660, 147, 3, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (660, 20, 10, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (660, 56, 7, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (661, 56, 4, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (661, 16, 1, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (661, 192, 10, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (662, 76, 5, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (662, 186, 3, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (662, 2, 9, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (662, 160, 4, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (662, 70, 5, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (662, 116, 10, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (662, 81, 6, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (663, 148, 3, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (663, 121, 3, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (664, 64, 5, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (664, 175, 3, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (664, 192, 3, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (665, 178, 4, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (665, 77, 5, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (665, 39, 5, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (665, 81, 9, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (665, 143, 1, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (666, 139, 1, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (666, 103, 5, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (666, 162, 9, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (666, 138, 2, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (666, 82, 10, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (666, 17, 1, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (667, 73, 4, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (667, 45, 7, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (667, 140, 7, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (668, 57, 9, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (669, 113, 2, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (669, 21, 8, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (669, 153, 3, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (669, 116, 1, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (670, 169, 6, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (671, 47, 10, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (671, 119, 6, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (672, 89, 10, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (672, 88, 7, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (672, 84, 3, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (672, 92, 6, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (672, 178, 7, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (672, 63, 7, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (672, 160, 7, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (672, 106, 2, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (673, 178, 3, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (673, 168, 6, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (673, 81, 10, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (673, 117, 10, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (673, 54, 5, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (673, 71, 5, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (674, 141, 5, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (674, 6, 10, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (674, 104, 1, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (674, 176, 9, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (674, 21, 5, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (675, 124, 4, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (675, 151, 10, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (675, 47, 10, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (675, 188, 7, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (675, 112, 4, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (676, 159, 5, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (676, 56, 8, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (677, 35, 8, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (677, 181, 6, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (677, 51, 2, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (677, 76, 4, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (678, 13, 1, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (678, 181, 9, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (678, 109, 3, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (678, 125, 3, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (678, 130, 3, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (679, 190, 9, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (679, 165, 5, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (679, 86, 10, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (679, 164, 9, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (679, 30, 9, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (679, 57, 8, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (679, 134, 2, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (679, 123, 4, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (680, 53, 7, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (680, 29, 6, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (680, 82, 2, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (680, 199, 10, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (680, 122, 6, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (680, 62, 6, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (681, 140, 3, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (681, 193, 10, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (681, 65, 5, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (681, 161, 4, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (681, 102, 9, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (681, 64, 1, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (682, 75, 3, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (682, 88, 6, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (682, 67, 3, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (682, 45, 7, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (682, 159, 2, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (682, 24, 7, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (683, 122, 4, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (683, 193, 4, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (683, 58, 9, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (684, 116, 1, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (684, 69, 5, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (684, 47, 4, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (684, 45, 2, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (684, 191, 2, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (685, 135, 6, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (685, 2, 9, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (685, 13, 8, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (686, 52, 8, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (686, 139, 6, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (686, 34, 7, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (686, 108, 5, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (686, 113, 4, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (686, 107, 4, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (686, 157, 4, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (687, 4, 4, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (687, 182, 4, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (687, 53, 9, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (687, 167, 1, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (688, 9, 9, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (688, 10, 10, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (688, 172, 9, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (688, 154, 5, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (688, 179, 2, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (688, 102, 10, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (689, 102, 10, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (689, 88, 1, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (689, 84, 10, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (689, 53, 7, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (689, 86, 10, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (689, 9, 1, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (690, 147, 8, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (690, 23, 5, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (690, 164, 6, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (690, 91, 8, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (690, 182, 7, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (690, 76, 9, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (690, 62, 8, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (691, 119, 3, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (691, 91, 8, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (691, 66, 9, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (691, 164, 5, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (692, 115, 3, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (692, 20, 9, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (693, 62, 8, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (693, 88, 8, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (693, 133, 7, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (693, 39, 1, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (693, 179, 10, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (693, 1, 10, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (693, 4, 10, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (694, 60, 10, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (694, 129, 5, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (694, 76, 2, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (694, 152, 2, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (694, 8, 5, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (694, 36, 6, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (694, 26, 3, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (695, 164, 7, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (695, 168, 2, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (695, 143, 8, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (696, 144, 6, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (696, 173, 9, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (696, 106, 9, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (696, 117, 8, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (697, 133, 7, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (697, 138, 4, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (697, 75, 3, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (697, 13, 9, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (698, 176, 4, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (698, 103, 3, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (698, 173, 4, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (698, 53, 10, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (698, 165, 7, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (698, 140, 3, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (698, 8, 5, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (699, 160, 8, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (699, 195, 3, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (699, 169, 10, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (699, 170, 9, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (699, 64, 9, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (699, 47, 5, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (699, 54, 3, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (699, 157, 6, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (700, 130, 7, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (700, 66, 3, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (700, 88, 5, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (700, 134, 1, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (701, 144, 5, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (701, 114, 5, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (701, 178, 5, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (701, 189, 1, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (701, 188, 5, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (702, 112, 4, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (702, 28, 5, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (703, 36, 6, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (704, 157, 5, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (704, 182, 8, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (704, 42, 8, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (704, 37, 10, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (705, 56, 6, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (705, 119, 10, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (705, 96, 8, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (705, 197, 1, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (705, 152, 8, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (705, 161, 7, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (705, 129, 9, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (706, 57, 6, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (706, 180, 8, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (707, 184, 6, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (707, 173, 7, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (707, 155, 6, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (707, 131, 2, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (708, 66, 1, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (708, 85, 9, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (708, 24, 5, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (708, 173, 8, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (708, 58, 2, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (708, 9, 6, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (708, 42, 1, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (708, 166, 2, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (709, 99, 5, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (709, 152, 10, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (709, 90, 3, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (709, 158, 9, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (710, 9, 8, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (710, 17, 8, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (710, 65, 6, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (710, 104, 8, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (710, 183, 4, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (710, 109, 9, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (710, 10, 1, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (711, 92, 1, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (711, 109, 7, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (711, 32, 2, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (711, 20, 9, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (711, 6, 10, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (711, 113, 9, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (711, 81, 7, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (712, 197, 10, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (712, 198, 4, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (712, 19, 3, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (713, 88, 10, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (713, 9, 7, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (713, 106, 2, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (714, 158, 1, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (714, 177, 5, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (715, 167, 7, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (715, 185, 4, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (716, 187, 4, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (716, 181, 4, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (717, 10, 2, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (717, 128, 7, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (718, 76, 2, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (718, 79, 5, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (718, 192, 9, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (718, 185, 3, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (718, 16, 1, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (719, 114, 10, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (719, 155, 10, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (719, 138, 2, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (719, 192, 9, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (720, 12, 9, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (720, 192, 1, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (720, 132, 5, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (720, 71, 9, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (720, 172, 7, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (720, 58, 1, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (720, 59, 5, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (720, 88, 4, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (721, 75, 6, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (721, 161, 1, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (721, 116, 4, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (721, 117, 10, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (721, 98, 4, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (722, 148, 5, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (722, 20, 7, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (723, 77, 6, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (723, 141, 7, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (723, 113, 8, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (723, 88, 7, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (723, 178, 4, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (723, 191, 9, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (723, 38, 8, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (724, 156, 1, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (724, 163, 5, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (724, 103, 5, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (724, 114, 10, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (724, 50, 1, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (724, 19, 7, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (724, 182, 7, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (725, 46, 5, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (725, 11, 3, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (725, 102, 6, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (726, 34, 8, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (727, 152, 8, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (727, 30, 8, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (728, 130, 9, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (728, 192, 3, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (728, 120, 1, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (728, 106, 1, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (728, 126, 8, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (728, 179, 7, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (728, 109, 6, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (728, 70, 3, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (729, 139, 1, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (729, 177, 2, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (730, 60, 10, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (730, 72, 3, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (730, 139, 7, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (730, 183, 1, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (730, 42, 10, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (730, 131, 1, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (731, 11, 4, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (731, 200, 8, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (731, 81, 2, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (731, 52, 2, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (731, 183, 3, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (731, 44, 5, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (731, 37, 2, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (731, 66, 7, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (732, 21, 9, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (732, 8, 9, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (732, 113, 3, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (732, 130, 5, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (732, 124, 4, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (733, 82, 8, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (733, 197, 1, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (733, 117, 6, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (733, 115, 2, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (733, 161, 1, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (734, 58, 1, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (734, 174, 5, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (734, 117, 8, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (734, 14, 6, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (735, 152, 6, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (736, 66, 9, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (736, 31, 4, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (737, 79, 6, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (737, 66, 6, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (737, 49, 6, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (738, 4, 8, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (738, 96, 4, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (738, 151, 5, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (738, 157, 4, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (738, 3, 10, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (738, 20, 6, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (739, 183, 3, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (739, 172, 5, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (739, 145, 10, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (740, 45, 9, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (740, 134, 9, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (740, 26, 2, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (740, 46, 6, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (740, 108, 1, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (740, 166, 1, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (741, 4, 5, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (742, 167, 6, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (742, 159, 1, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (743, 183, 4, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (743, 104, 9, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (743, 13, 8, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (744, 161, 5, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (744, 43, 10, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (744, 65, 3, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (744, 71, 8, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (744, 68, 5, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (745, 101, 3, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (745, 31, 10, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (745, 58, 8, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (745, 49, 1, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (745, 9, 1, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (745, 191, 3, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (746, 10, 8, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (746, 155, 2, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (746, 161, 2, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (747, 156, 9, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (747, 118, 8, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (747, 161, 8, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (748, 116, 10, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (748, 79, 9, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (748, 122, 5, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (748, 33, 9, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (749, 178, 2, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (750, 78, 1, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (750, 90, 2, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (750, 162, 8, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (750, 182, 7, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (750, 123, 5, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (750, 12, 3, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (750, 17, 6, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (750, 166, 8, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (751, 130, 3, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (751, 117, 8, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (751, 58, 4, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (751, 172, 4, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (751, 133, 3, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (751, 19, 10, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (751, 99, 8, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (752, 150, 9, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (752, 54, 3, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (752, 34, 9, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (752, 130, 9, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (752, 191, 3, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (752, 143, 8, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (753, 48, 1, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (753, 148, 1, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (754, 148, 2, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (754, 17, 9, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (754, 40, 8, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (754, 81, 5, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (754, 127, 1, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (754, 41, 10, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (754, 70, 4, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (754, 3, 5, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (755, 176, 7, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (755, 95, 7, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (755, 187, 1, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (755, 59, 2, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (756, 149, 3, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (756, 162, 3, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (756, 179, 5, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (756, 159, 8, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (756, 41, 3, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (756, 172, 5, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (757, 165, 2, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (757, 81, 9, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (758, 131, 1, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (759, 173, 2, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (759, 147, 10, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (759, 31, 6, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (759, 65, 3, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (759, 166, 10, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (759, 69, 9, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (760, 171, 8, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (760, 68, 10, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (760, 19, 2, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (760, 7, 8, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (760, 119, 10, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (760, 78, 6, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (761, 92, 6, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (761, 51, 1, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (762, 118, 3, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (762, 84, 6, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (762, 20, 10, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (763, 177, 5, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (764, 45, 8, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (765, 4, 9, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (765, 137, 7, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (766, 122, 8, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (767, 147, 6, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (767, 186, 9, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (767, 15, 8, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (767, 88, 9, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (767, 200, 4, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (768, 156, 2, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (768, 36, 8, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (768, 130, 3, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (768, 90, 1, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (768, 76, 10, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (768, 139, 9, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (768, 107, 10, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (769, 182, 1, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (769, 88, 6, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (769, 40, 3, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (770, 163, 9, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (770, 72, 6, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (770, 53, 2, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (770, 108, 2, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (771, 39, 3, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (771, 13, 1, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (771, 31, 10, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (771, 147, 3, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (772, 199, 3, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (772, 90, 9, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (772, 35, 4, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (773, 69, 1, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (773, 45, 9, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (773, 25, 10, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (774, 186, 1, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (774, 49, 3, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (774, 71, 6, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (774, 9, 6, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (775, 188, 4, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (775, 156, 9, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (775, 124, 9, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (775, 85, 1, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (775, 183, 2, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (775, 123, 8, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (775, 180, 7, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (776, 51, 9, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (776, 167, 2, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (776, 36, 7, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (776, 59, 10, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (776, 145, 8, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (777, 47, 7, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (777, 22, 3, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (777, 159, 6, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (778, 169, 6, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (778, 48, 2, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (778, 80, 1, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (778, 197, 8, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (778, 61, 10, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (778, 73, 8, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (779, 55, 5, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (779, 182, 9, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (779, 44, 5, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (779, 89, 3, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (780, 106, 10, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (780, 117, 1, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (780, 96, 8, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (780, 77, 10, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (780, 102, 3, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (780, 84, 5, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (780, 34, 5, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (781, 51, 2, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (781, 176, 10, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (781, 88, 2, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (782, 10, 10, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (782, 1, 9, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (782, 79, 2, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (783, 89, 8, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (783, 197, 6, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (783, 133, 10, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (783, 187, 7, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (783, 164, 9, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (783, 2, 8, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (783, 168, 1, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (784, 53, 3, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (784, 191, 3, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (784, 84, 5, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (784, 106, 4, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (785, 149, 2, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (785, 102, 10, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (785, 151, 3, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (785, 137, 7, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (785, 105, 4, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (785, 38, 8, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (785, 104, 1, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (785, 186, 1, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (786, 17, 9, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (786, 20, 4, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (786, 24, 5, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (787, 117, 8, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (787, 33, 6, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (787, 197, 4, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (788, 169, 4, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (788, 24, 6, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (788, 104, 4, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (788, 34, 6, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (789, 194, 5, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (789, 44, 7, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (789, 169, 5, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (789, 57, 4, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (789, 156, 7, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (789, 22, 10, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (789, 28, 4, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (790, 121, 4, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (790, 46, 9, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (790, 54, 5, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (790, 16, 2, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (791, 138, 5, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (791, 53, 2, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (792, 142, 9, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (792, 54, 1, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (792, 16, 1, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (792, 136, 9, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (792, 8, 1, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (792, 2, 10, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (793, 21, 10, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (793, 63, 10, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (793, 171, 7, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (794, 13, 5, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (794, 59, 4, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (794, 62, 6, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (794, 7, 1, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (794, 196, 4, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (794, 161, 10, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (794, 83, 9, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (794, 124, 3, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (795, 147, 2, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (795, 145, 7, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (795, 176, 1, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (795, 138, 7, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (795, 114, 7, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (795, 128, 5, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (796, 53, 5, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (797, 9, 10, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (797, 186, 2, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (797, 131, 3, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (797, 5, 1, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (797, 178, 5, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (797, 60, 10, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (797, 148, 7, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (797, 125, 3, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (798, 163, 8, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (798, 127, 2, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (799, 174, 8, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (799, 177, 10, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (800, 98, 3, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (800, 148, 9, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (801, 161, 9, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (801, 72, 9, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (801, 61, 1, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (801, 59, 10, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (802, 12, 5, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (803, 40, 8, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (803, 125, 10, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (803, 112, 5, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (803, 53, 10, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (803, 101, 4, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (803, 35, 1, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (803, 99, 7, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (803, 160, 8, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (804, 152, 4, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (804, 138, 1, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (804, 116, 8, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (805, 30, 3, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (805, 36, 2, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (806, 90, 7, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (806, 74, 3, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (806, 48, 8, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (806, 94, 8, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (806, 39, 3, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (806, 103, 5, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (806, 110, 2, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (807, 37, 4, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (807, 163, 1, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (807, 54, 2, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (807, 86, 10, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (807, 183, 5, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (807, 20, 2, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (807, 145, 5, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (808, 45, 4, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (808, 177, 10, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (808, 52, 10, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (808, 16, 6, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (808, 107, 9, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (808, 147, 6, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (809, 87, 8, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (809, 137, 4, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (809, 61, 4, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (809, 93, 4, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (809, 88, 10, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (809, 90, 3, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (809, 178, 8, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (809, 13, 5, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (810, 87, 4, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (810, 145, 7, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (811, 175, 10, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (811, 168, 3, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (811, 127, 6, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (811, 47, 5, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (811, 154, 9, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (812, 181, 4, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (812, 79, 8, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (812, 69, 3, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (812, 136, 8, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (812, 68, 1, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (812, 97, 4, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (812, 73, 5, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (812, 150, 1, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (813, 68, 5, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (813, 42, 5, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (814, 105, 2, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (814, 25, 3, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (815, 162, 10, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (815, 106, 1, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (815, 185, 10, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (815, 115, 5, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (815, 153, 7, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (816, 122, 1, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (816, 63, 6, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (817, 195, 8, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (817, 178, 8, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (818, 132, 7, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (819, 19, 3, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (819, 29, 2, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (819, 12, 5, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (819, 103, 7, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (819, 71, 9, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (819, 54, 2, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (819, 196, 1, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (820, 88, 9, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (820, 20, 4, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (820, 28, 8, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (820, 41, 8, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (820, 156, 4, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (820, 15, 5, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (820, 175, 1, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (821, 183, 5, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (821, 180, 8, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (821, 106, 5, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (821, 125, 4, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (821, 164, 9, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (821, 74, 9, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (821, 86, 6, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (821, 105, 5, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (822, 95, 7, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (823, 24, 6, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (823, 118, 3, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (823, 154, 2, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (823, 66, 9, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (824, 99, 4, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (824, 119, 10, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (824, 172, 8, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (825, 86, 10, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (825, 102, 3, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (825, 155, 6, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (825, 145, 3, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (825, 196, 3, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (825, 34, 8, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (825, 151, 10, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (825, 110, 7, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (826, 119, 2, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (826, 17, 9, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (826, 26, 7, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (826, 185, 6, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (826, 66, 4, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (826, 165, 6, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (826, 171, 3, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (827, 110, 2, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (827, 44, 1, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (828, 168, 8, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (828, 39, 8, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (828, 138, 3, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (828, 127, 7, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (828, 56, 2, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (828, 145, 6, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (828, 32, 9, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (829, 33, 5, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (829, 56, 4, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (829, 143, 7, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (829, 91, 9, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (829, 58, 5, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (829, 37, 7, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (830, 88, 5, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (830, 75, 5, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (830, 94, 2, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (830, 28, 6, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (830, 137, 6, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (830, 10, 3, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (831, 10, 2, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (831, 19, 2, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (831, 157, 8, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (831, 96, 3, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (831, 185, 4, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (831, 172, 3, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (831, 31, 8, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (831, 126, 3, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (832, 89, 4, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (832, 1, 2, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (832, 113, 2, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (832, 115, 10, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (832, 49, 8, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (832, 77, 8, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (832, 160, 2, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (832, 39, 3, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (833, 38, 2, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (833, 120, 10, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (833, 23, 4, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (834, 21, 5, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (834, 22, 6, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (834, 36, 7, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (834, 78, 6, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (834, 77, 10, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (834, 26, 9, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (835, 99, 10, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (835, 74, 1, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (836, 65, 3, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (836, 24, 9, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (836, 171, 10, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (836, 39, 5, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (836, 43, 7, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (836, 7, 6, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (836, 28, 10, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (837, 15, 5, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (837, 23, 10, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (837, 193, 5, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (837, 76, 2, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (837, 158, 3, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (837, 13, 2, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (838, 187, 1, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (838, 71, 7, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (838, 110, 7, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (838, 152, 10, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (838, 89, 9, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (839, 183, 7, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (839, 176, 4, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (840, 37, 4, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (840, 133, 3, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (840, 83, 9, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (840, 46, 8, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (840, 10, 2, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (841, 63, 8, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (841, 1, 3, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (841, 40, 4, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (841, 118, 2, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (841, 142, 3, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (841, 133, 7, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (841, 64, 10, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (841, 29, 1, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (842, 111, 10, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (843, 79, 1, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (844, 195, 10, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (844, 200, 4, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (844, 42, 1, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (844, 86, 4, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (845, 9, 1, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (846, 10, 1, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (846, 174, 5, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (846, 33, 8, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (846, 108, 6, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (847, 85, 7, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (847, 61, 2, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (848, 24, 2, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (848, 127, 5, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (848, 159, 4, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (848, 44, 3, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (848, 150, 1, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (849, 194, 10, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (849, 161, 10, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (849, 177, 4, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (849, 151, 8, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (850, 14, 6, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (850, 78, 4, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (850, 61, 6, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (850, 15, 1, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (850, 82, 4, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (850, 140, 3, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (850, 66, 2, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (851, 171, 5, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (851, 48, 3, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (851, 85, 10, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (852, 23, 4, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (852, 176, 8, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (852, 81, 9, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (852, 191, 1, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (852, 86, 3, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (852, 40, 6, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (852, 162, 5, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (853, 113, 9, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (853, 118, 7, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (853, 76, 7, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (854, 50, 9, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (854, 117, 5, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (855, 25, 3, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (855, 42, 9, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (855, 1, 7, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (855, 117, 3, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (855, 195, 10, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (855, 142, 7, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (855, 98, 6, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (856, 152, 6, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (856, 4, 5, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (856, 151, 6, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (856, 10, 1, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (856, 127, 4, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (856, 33, 8, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (856, 191, 6, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (856, 29, 8, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (857, 126, 2, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (858, 27, 7, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (858, 187, 5, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (858, 130, 7, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (858, 192, 8, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (858, 33, 4, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (859, 69, 4, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (859, 135, 5, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (859, 170, 3, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (859, 90, 10, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (859, 190, 6, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (859, 87, 9, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (859, 80, 7, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (859, 89, 1, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (860, 24, 9, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (860, 137, 7, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (860, 71, 7, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (860, 42, 9, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (861, 73, 10, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (861, 159, 6, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (861, 93, 3, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (861, 24, 7, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (861, 168, 1, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (862, 8, 7, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (862, 124, 10, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (862, 100, 8, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (862, 17, 8, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (862, 71, 9, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (862, 1, 8, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (862, 181, 8, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (863, 133, 5, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (863, 105, 6, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (863, 130, 8, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (863, 63, 6, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (863, 103, 9, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (863, 143, 3, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (863, 80, 10, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (864, 117, 6, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (864, 100, 7, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (864, 105, 4, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (865, 51, 4, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (865, 121, 4, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (866, 92, 3, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (866, 16, 8, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (866, 31, 1, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (866, 5, 1, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (866, 59, 4, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (866, 165, 10, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (867, 197, 2, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (867, 136, 8, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (868, 156, 1, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (868, 128, 3, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (868, 33, 2, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (868, 71, 2, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (868, 141, 2, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (869, 18, 4, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (869, 86, 10, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (869, 8, 6, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (869, 149, 3, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (869, 49, 1, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (869, 20, 10, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (869, 66, 2, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (870, 32, 1, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (870, 142, 4, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (871, 156, 9, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (871, 43, 5, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (871, 177, 6, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (871, 12, 8, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (871, 85, 1, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (871, 103, 6, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (871, 119, 10, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (872, 101, 6, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (872, 9, 10, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (872, 73, 10, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (872, 128, 6, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (872, 166, 4, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (872, 83, 2, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (872, 28, 10, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (873, 120, 3, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (873, 199, 6, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (873, 23, 5, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (873, 159, 7, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (874, 179, 5, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (874, 96, 4, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (875, 198, 3, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (875, 39, 7, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (875, 106, 9, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (875, 18, 3, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (875, 142, 8, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (875, 177, 6, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (875, 111, 2, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (876, 114, 6, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (877, 23, 5, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (877, 36, 3, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (877, 72, 5, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (877, 46, 1, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (878, 199, 4, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (878, 63, 2, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (878, 198, 1, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (878, 8, 9, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (878, 48, 7, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (879, 71, 10, 59);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (879, 177, 4, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (879, 195, 8, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (879, 25, 6, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (879, 139, 4, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (880, 14, 9, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (880, 47, 8, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (880, 9, 2, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (881, 45, 1, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (881, 186, 6, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (881, 97, 6, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (881, 24, 4, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (881, 167, 10, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (881, 107, 10, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (881, 28, 4, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (882, 138, 9, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (883, 169, 7, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (884, 163, 7, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (884, 58, 5, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (885, 53, 10, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (885, 173, 5, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (885, 200, 5, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (885, 16, 8, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (885, 6, 10, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (885, 91, 2, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (885, 153, 2, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (886, 66, 7, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (887, 43, 2, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (888, 88, 4, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (888, 49, 2, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (888, 106, 3, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (888, 34, 8, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (888, 23, 1, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (888, 18, 8, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (888, 21, 4, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (888, 52, 9, 23);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (889, 73, 9, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (889, 89, 6, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (889, 76, 2, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (889, 137, 10, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (889, 38, 1, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (889, 6, 9, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (889, 52, 10, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (889, 175, 4, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (890, 179, 9, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (891, 164, 7, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (891, 126, 3, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (891, 178, 8, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (891, 3, 7, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (891, 1, 4, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (892, 60, 9, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (892, 85, 6, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (892, 177, 3, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (892, 137, 10, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (893, 88, 2, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (893, 157, 6, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (893, 95, 6, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (893, 162, 8, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (893, 28, 3, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (893, 60, 1, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (893, 71, 9, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (893, 147, 7, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (894, 29, 4, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (894, 129, 6, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (894, 135, 7, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (894, 193, 3, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (894, 160, 2, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (894, 76, 6, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (894, 113, 4, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (894, 83, 7, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (895, 161, 10, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (895, 148, 8, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (895, 153, 6, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (895, 101, 6, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (896, 32, 6, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (896, 10, 3, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (896, 130, 7, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (896, 126, 9, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (897, 194, 5, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (897, 146, 5, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (897, 83, 3, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (898, 179, 1, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (898, 67, 4, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (898, 199, 4, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (898, 191, 9, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (898, 193, 10, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (898, 14, 6, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (899, 67, 10, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (900, 93, 10, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (901, 150, 6, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (901, 167, 1, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (901, 186, 8, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (901, 134, 8, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (901, 56, 10, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (901, 176, 7, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (901, 114, 2, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (902, 25, 5, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (902, 48, 8, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (902, 116, 6, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (902, 198, 10, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (902, 152, 6, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (902, 181, 7, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (902, 136, 2, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (902, 175, 6, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (903, 156, 9, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (903, 2, 4, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (903, 37, 5, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (903, 71, 7, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (903, 127, 1, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (903, 182, 5, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (903, 52, 2, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (903, 59, 8, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (904, 195, 8, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (904, 103, 7, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (904, 142, 5, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (904, 38, 10, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (904, 60, 6, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (905, 97, 2, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (905, 137, 8, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (905, 94, 8, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (905, 103, 10, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (905, 44, 2, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (905, 139, 10, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (905, 64, 9, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (906, 128, 9, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (906, 44, 5, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (906, 82, 10, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (907, 58, 5, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (907, 32, 6, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (907, 64, 1, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (908, 131, 3, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (908, 14, 9, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (908, 75, 4, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (908, 70, 5, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (908, 123, 2, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (908, 16, 8, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (908, 34, 9, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (908, 194, 4, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (909, 125, 1, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (909, 176, 9, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (909, 9, 10, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (909, 44, 10, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (909, 196, 7, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (909, 181, 4, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (909, 105, 9, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (909, 180, 5, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (910, 10, 4, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (910, 191, 3, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (910, 44, 2, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (910, 161, 6, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (910, 12, 8, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (910, 54, 10, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (911, 15, 9, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (911, 184, 7, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (911, 195, 7, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (911, 181, 2, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (911, 116, 6, 99);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (911, 2, 9, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (911, 167, 10, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (911, 37, 3, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (912, 168, 1, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (912, 117, 4, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (912, 15, 8, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (912, 157, 6, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (912, 28, 5, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (913, 96, 5, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (913, 128, 8, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (913, 82, 7, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (913, 42, 3, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (914, 196, 2, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (914, 56, 2, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (914, 110, 10, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (915, 117, 9, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (915, 183, 7, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (915, 29, 8, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (915, 14, 9, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (916, 53, 3, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (916, 187, 4, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (916, 130, 10, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (916, 170, 7, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (916, 196, 8, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (916, 134, 6, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (916, 107, 4, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (916, 64, 4, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (917, 119, 10, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (917, 88, 3, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (917, 43, 4, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (918, 187, 9, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (918, 5, 6, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (918, 13, 5, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (918, 165, 7, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (918, 48, 6, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (919, 160, 4, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (919, 114, 3, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (919, 30, 2, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (919, 105, 1, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (919, 191, 9, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (920, 155, 5, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (920, 47, 4, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (920, 123, 7, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (920, 18, 2, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (920, 45, 4, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (920, 8, 8, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (921, 51, 1, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (921, 127, 2, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (921, 187, 2, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (921, 175, 1, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (922, 13, 4, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (923, 28, 6, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (923, 132, 1, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (923, 108, 7, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (923, 91, 6, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (923, 177, 1, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (923, 141, 2, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (923, 57, 1, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (923, 77, 3, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (924, 159, 10, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (924, 120, 3, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (925, 189, 4, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (925, 141, 3, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (925, 152, 2, 27);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (925, 27, 4, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (925, 57, 10, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (926, 114, 9, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (926, 93, 9, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (926, 141, 10, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (926, 30, 5, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (927, 145, 3, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (927, 184, 4, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (927, 36, 6, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (928, 98, 9, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (928, 150, 10, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (928, 48, 3, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (928, 142, 4, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (929, 26, 8, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (929, 67, 9, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (929, 143, 7, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (929, 104, 6, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (929, 200, 5, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (929, 156, 9, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (929, 195, 7, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (929, 183, 3, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (930, 152, 8, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (930, 63, 9, 41);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (930, 70, 6, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (930, 79, 5, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (930, 200, 5, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (930, 20, 1, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (930, 186, 8, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (930, 42, 5, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (931, 195, 10, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (932, 46, 3, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (932, 13, 2, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (932, 36, 10, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (932, 191, 7, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (933, 35, 2, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (933, 51, 4, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (933, 141, 2, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (933, 36, 8, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (934, 97, 10, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (934, 76, 2, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (934, 38, 8, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (934, 135, 6, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (934, 159, 2, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (934, 95, 8, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (934, 137, 2, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (934, 78, 3, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (935, 149, 9, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (935, 94, 9, 21);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (936, 71, 2, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (936, 193, 6, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (936, 6, 3, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (937, 26, 2, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (938, 31, 2, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (938, 130, 3, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (938, 186, 9, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (938, 4, 3, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (939, 162, 10, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (939, 160, 6, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (939, 38, 8, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (939, 4, 10, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (939, 68, 10, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (939, 109, 4, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (940, 133, 5, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (940, 110, 1, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (940, 96, 6, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (940, 90, 4, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (941, 14, 7, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (941, 95, 2, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (941, 76, 7, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (941, 170, 9, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (941, 75, 2, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (941, 113, 3, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (941, 107, 6, 79);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (941, 64, 1, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (942, 77, 4, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (942, 194, 6, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (942, 52, 9, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (942, 171, 5, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (942, 196, 8, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (943, 153, 2, 46);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (943, 83, 9, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (943, 59, 1, 80);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (943, 47, 5, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (943, 88, 10, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (943, 124, 4, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (944, 3, 1, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (945, 180, 10, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (945, 122, 2, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (945, 30, 10, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (945, 188, 2, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (946, 127, 5, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (946, 53, 5, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (946, 54, 3, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (946, 140, 8, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (946, 173, 2, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (947, 111, 8, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (947, 171, 3, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (948, 92, 4, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (948, 197, 3, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (948, 20, 9, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (948, 137, 8, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (949, 134, 3, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (949, 4, 6, 20);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (949, 200, 7, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (949, 5, 6, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (950, 33, 9, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (950, 49, 3, 86);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (950, 168, 2, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (951, 183, 7, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (952, 6, 9, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (952, 174, 5, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (953, 198, 9, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (953, 31, 1, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (953, 192, 1, 61);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (953, 3, 9, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (953, 114, 10, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (953, 105, 9, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (953, 42, 9, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (953, 53, 3, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (954, 26, 4, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (954, 12, 8, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (954, 90, 1, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (954, 95, 8, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (954, 11, 2, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (954, 39, 1, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (954, 177, 10, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (954, 105, 5, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (955, 6, 9, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (956, 73, 4, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (956, 32, 7, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (956, 18, 3, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (956, 125, 1, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (956, 23, 9, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (956, 87, 8, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (956, 65, 10, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (956, 122, 3, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (957, 193, 9, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (957, 68, 7, 66);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (957, 34, 5, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (957, 7, 1, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (958, 35, 6, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (958, 20, 1, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (958, 117, 2, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (958, 58, 2, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (958, 188, 9, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (959, 117, 6, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (959, 129, 8, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (960, 64, 2, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (961, 184, 8, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (961, 72, 8, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (961, 124, 10, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (961, 88, 5, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (961, 121, 5, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (962, 5, 10, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (962, 197, 4, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (962, 144, 10, 82);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (963, 194, 7, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (963, 49, 9, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (963, 69, 4, 25);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (963, 25, 1, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (963, 192, 1, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (964, 78, 10, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (964, 149, 4, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (965, 41, 4, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (965, 140, 5, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (965, 193, 9, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (965, 47, 10, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (965, 67, 2, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (965, 126, 3, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (966, 192, 10, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (966, 135, 5, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (967, 131, 6, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (967, 47, 5, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (967, 73, 1, 93);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (967, 148, 10, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (967, 198, 1, 91);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (967, 87, 7, 54);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (967, 14, 5, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (968, 121, 5, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (968, 168, 9, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (968, 159, 2, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (968, 141, 3, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (968, 152, 5, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (969, 29, 9, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (969, 140, 8, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (969, 130, 8, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (970, 139, 2, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (970, 123, 5, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (970, 113, 8, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (970, 110, 10, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (971, 133, 2, 65);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (971, 38, 8, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (971, 195, 7, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (972, 181, 5, 36);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (972, 122, 9, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (972, 144, 9, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (972, 151, 2, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (972, 99, 2, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (972, 49, 10, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (972, 124, 8, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (972, 94, 10, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (973, 199, 4, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (973, 103, 7, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (973, 24, 4, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (973, 137, 8, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (974, 179, 6, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (974, 195, 10, 13);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (974, 168, 6, 75);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (975, 113, 1, 49);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (975, 140, 6, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (975, 95, 5, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (976, 90, 5, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (976, 178, 5, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (977, 119, 1, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (977, 126, 8, 40);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (977, 32, 5, 57);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (977, 150, 1, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (977, 177, 5, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (978, 19, 4, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (978, 161, 9, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (978, 199, 7, 32);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (978, 114, 5, 64);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (978, 162, 10, 43);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (978, 24, 10, 29);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (978, 170, 2, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (978, 32, 5, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (979, 36, 5, 71);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (979, 178, 8, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (979, 17, 6, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (980, 49, 9, 16);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (980, 14, 8, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (980, 10, 7, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (980, 139, 6, 12);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (980, 167, 4, 39);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (981, 25, 8, 55);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (981, 86, 2, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (981, 4, 2, 22);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (982, 34, 2, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (982, 159, 5, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (982, 72, 8, 52);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (983, 89, 7, 70);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (983, 74, 2, 76);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (983, 165, 2, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (983, 120, 10, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (983, 42, 2, 68);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (983, 21, 1, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (983, 36, 8, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (984, 81, 4, 87);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (984, 72, 1, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (984, 70, 7, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (984, 77, 3, 96);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (985, 124, 9, 100);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (985, 22, 10, 94);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (986, 167, 6, 51);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (986, 51, 7, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (987, 182, 9, 38);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (987, 66, 5, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (987, 73, 4, 89);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (987, 129, 6, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (987, 195, 4, 69);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (988, 141, 10, 48);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (988, 70, 5, 77);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (988, 47, 2, 15);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (989, 1, 4, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (989, 28, 5, 35);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (989, 121, 1, 78);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (989, 136, 2, 26);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (989, 29, 2, 14);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (989, 189, 6, 44);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (989, 104, 2, 88);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (990, 28, 1, 58);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (990, 92, 1, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (990, 21, 8, 67);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (990, 91, 10, 45);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (990, 66, 3, 34);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (990, 107, 9, 24);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (990, 171, 10, 74);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (991, 84, 2, 10);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (991, 71, 8, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (991, 137, 2, 37);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (991, 115, 1, 28);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (992, 48, 3, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (992, 42, 9, 73);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (992, 189, 1, 60);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (992, 44, 6, 85);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (993, 159, 9, 98);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (993, 36, 2, 19);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (994, 153, 5, 31);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (994, 68, 10, 84);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (994, 160, 7, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (994, 123, 3, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (994, 179, 3, 62);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (994, 142, 2, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (994, 37, 3, 56);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (994, 117, 1, 92);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (995, 46, 6, 95);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (995, 156, 2, 33);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (995, 71, 2, 63);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (995, 167, 3, 90);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (995, 110, 6, 97);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (995, 126, 6, 53);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (996, 183, 10, 11);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (996, 169, 8, 17);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (997, 87, 9, 72);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (998, 103, 5, 50);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (998, 163, 1, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (998, 151, 7, 30);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (998, 190, 2, 47);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (998, 125, 6, 83);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (999, 35, 10, 18);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (999, 115, 8, 81);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (999, 191, 8, 42);
INSERT INTO item_venda (venda_id, produto_id, quant, valor) VALUES (1000, 112, 1, 85);
