package com.example;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

import com.example.model.Cliente;

public class ClienteTest {
    @Test
    void testGetIdade() {
        var cliente = new Cliente();
        assertEquals( 42, cliente.idade());
    }
}
