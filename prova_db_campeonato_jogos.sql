--tables

create table modalidades(
id serial primary key,
nome varchar(50) unique not null
);

--

create table jogadores(
id serial primary key,
nome varchar(50) not null,
nickname varchar(50) unique not null,
email varchar(50) unique not null,
senha varchar(100) not null,
equipe varchar(50) not null,
ativo boolean default true not null
);

--

create table partidas(
id serial primary key,
titulo varchar(100),
jogador_id int not null references jogadores(id),
modalidade_id int not null references modalidades(id),
equipe_casa varchar(50) not null,
equipe_rival varchar(50) not null,
pontuacao_casa numeric default 0 not null,
pontuacao_rival numeric default 0 not null,
data_partida timestamp not null,
status varchar(20) default 'agendada' not null,
data_criacao timestamp
);

--

create table historico_partidas(
id serial primary key,
partida_id int not null,
jogador_id int not null,
acao varchar(100) not null,
data_registro timestamp default current_timestamp not null
);

--
