package com.example.financeiro.model;

import static org.junit.jupiter.api.Assertions.*;

import java.time.LocalDateTime;

import org.junit.jupiter.api.Test;

import com.example.financeiro.dao.TransacaoDAO;

public class TransacaoTest {
    private TransacaoDAO dao = new TransacaoDAO();

    @Test
    void adicionarTransacoesRetiradaNaoSuspeitas() {
        dao.adicionar(new Transacao("Manoel", 100, "BRL", 'R'));
        var ultima = dao.adicionar(new Transacao("Manoel",  50, "BRL", 'R'));
        assertFalse(ultima.isSuspeita());
    }

    @Test
    void adicionarTransacoesUmaRetiradaNaoSuspeita() {
        var ultima = dao.adicionar(new Transacao("Manoel",  70, "BRL", 'R'));
        assertFalse(ultima.isSuspeita());
    }

    @Test
    void adicionarTransacoesTransferenciaNaoSuspeitas() {
        dao.adicionar(new Transacao("Manoel", 100, "BRL", 'T'));
        dao.adicionar(new Transacao("Manoel", 200, "BRL", 'T'));
        var ultima = dao.adicionar(new Transacao("Manoel",  50, "BRL", 'T'));

        assertFalse(ultima.isSuspeita());
    }

    @Test
    void adicionarTransacoesRetiradasSuspeitas() {
        dao.adicionar(new Transacao("Manoel", 100, "BRL", 'R'));
        dao.adicionar(new Transacao("Manoel", 200, "BRL", 'R'));
        var ultima = dao.adicionar(new Transacao("Manoel",  50, "BRL", 'R'));

        assertTrue(ultima.isSuspeita());
    }

    @Test
    void adicionarTransacoesRetiradasDiasDiferentes() {
        var anteontem = LocalDateTime.now().minusDays(2);
        var primeira = new Transacao("Manoel", 100, "BRL", 'R', anteontem);
        dao.adicionar(primeira);
        
        dao.adicionar(new Transacao("Manoel", 200, "BRL", 'R'));
        var ultima = dao.adicionar(new Transacao("Manoel",  50, "BRL", 'R'));

        assertFalse(ultima.isSuspeita());
    }
}
