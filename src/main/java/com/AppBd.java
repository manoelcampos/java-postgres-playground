package com;
import java.sql.DriverManager;
import java.sql.SQLException;

public class AppBd {
    public static void main(String[] args) {
        try {
            Class.forName("org.postgresql.Driver");
            try (var conn = DriverManager.getConnection("jdbc:postgresql://localhost/postgres", "gitpod", "");){
                System.out.println("Conectado ao banco de dados com sucesso!");

                var statement = conn.createStatement();
                var result = statement.executeQuery("select * from estado");
                while(result.next()){
                    System.out.printf("Id: %d Nome: %s UF: %s\n", result.getInt("id"), result.getString("nome"), result.getString("uf"));
                }
            }
        } catch (ClassNotFoundException e) {
                System.err.println("Não foi possível carregar a biblioteca para acessar o banco de dados: " + e.getMessage());
        } catch (SQLException e){
                System.out.println("Não foi possível conectar ao banco de dados: " + e.getMessage());
        } 
    }
}
