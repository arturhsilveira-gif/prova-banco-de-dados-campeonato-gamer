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

-- inserts

insert into modalidades (nome) values
('Counter-Strike 2'),
('Valorant'),
('League of Legends');

insert into jogadores (nome, nickname, email, senha, equipe, ativo) values
('Juliano', 'janiu_foguetes', 'juliano@gmail.com', 'senha123', 'Bulls', true),
('João Vitor', 'jojo_do_grau', 'joao@gmail.com', 'bulls2026', 'Bulls', true),
('Cleber', 'cleberiano', 'cleber@gmail.com', 'stones@1', 'Rolling Stones', true),
('Wilson', 'sr.wilson', 'wilson@gmail.com', 'wilson99', 'Rolling Stones', false);

insert into partidas (titulo, jogador_id, modalidade_id, equipe_casa, equipe_rival, data_partida)
values
('Final Regional - Jogo 1', 1, 1, 'Bulls', 'Rolling Stones', current_timestamp - INTERVAL '2 days'),
('Semifinal Open Cup', 3, 2, 'Rolling Stones', 'Bulls', current_timestamp + INTERVAL '5 days'),
('Desafio da Semana', 2, 3, 'Bulls', 'Alpha Team', current_timestamp + INTERVAL '1 day');
insert into partidas ( titulo, jogador_id, modalidade_id, equipe_casa, equipe_rival, data_partida) values
('Partida Bloqueada', 4, 1, 'Rolling Stones', 'Bulls', current_timestamp + INTERVAL '3 days');

--funcitions

create or replace function fn_validar_dados_partida()
returns trigger as $$
declare
    v_jogador_ativo boolean;
begin
    select ativo into v_jogador_ativo
    from jogadores
    where id = new.jogador_id;

	if v_jogador_ativo is null then
        raise exception 'Erro: O jogador informado (ID %) não existe.', new.jogador_id;
    elsif v_jogador_ativo = false then
        raise exception 'Operação bloqueada: O jogador (ID %) está banido ou inativo.', new.jogador_id;
    end if;

	new.data_criacao := current_timestamp;
    return new;
end;
$$ language plpgsql;

create trigger trg_validar_partida
before insert on partidas
for each row
execute function fn_validar_dados_partida();
create or replace function fn_registrar_log_partida()
returns trigger as $$
begin
    insert into historico_partidas (partida_id, jogador_id, acao, data_registro)
    values (
        new.id,
        new.jogador_id,
        'Partida criada: ' || new.titulo || ' (' || new.status || ')',
        current_timestamp
    );
    return new;
end;
$$ language plpgsql;
create trigger trg_log_historico_partida
after insert on partidas
for each row
execute function fn_registrar_log_partida();

--

create or replace function fn_buscar_jogadores(p_termo varchar)
returns table (
    id int,
    nome varchar,
    nickname varchar,
    email varchar,
    equipe varchar,
    ativo boolean
) as $$
begin
    return query
    select
        j.id,
        j.nome,
        j.nickname,
        j.email,
        j.equipe,
        j.ativo
    from jogadores j
    where j.nickname ilike '%' || p_termo || '%'
       or j.email ilike '%' || p_termo || '%';
end;
$$ language plpgsql;

--

create or replace view vw_painel_principal as
select
    j.nickname as jogador_nickname,
    p.titulo as titulo_partida,
    m.nome as modalidade,
    p.data_partida,
    p.status as status_disputa
from partidas p
inner join jogadores j on p.jogador_id = j.id
inner join modalidades m on p.modalidade_id = m.id;

create or replace view vw_cronograma_partidas as
select
    p.id as partida_id,
    p.titulo as confronto,
    p.data_partida as data_agendamento,
    p.status as status_partida,
    greatest(0, extract(day from (p.data_partida - current_timestamp)))::int as dias_restantes,
    j.nickname as jogador_responsavel
from partidas p
inner join jogadores j on p.jogador_id = j.id
order by p.data_partida asc;

-- consulta das vw

-- consulta do painel principal
select * from vw_painel_principal;

-- consultar cronograma ordenado
select * from vw_cronograma_partidas;

-- testar function de busca
select * from fn_buscar_jogadores('janiu');

-- verificar logs gerados automaticamente
select * from historico_partidas;
