package com.hugonavarro.tema02.ejercicio3;

import com.hugonavarro.tema02.Conexion;

import java.sql.*;

public class ResumenEtapasPorTipo {
    public static void resumenEtapasPorTipo() {
        String sql = """
                SELECT
                    tipo,
                    COUNT(*) AS cantidad_etapas,
                    SUM(distancia_km) AS kilometros_totales
                FROM etapas
                GROUP BY tipo
                ORDER BY tipo
                """;

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()
        ) {
            IO.println("\n=================");
            IO.println("RESUMEN DE ETAPAS");
            IO.println("=================");

            System.out.printf("\n%-15s %-20s %-20s%n", "TIPO", "N.º DE ETAPAS", "KILÓMETROS");

            IO.println("------------------------------------------------------------");

            while (rs.next()) {
                String tipo = rs.getString("tipo");
                int cantidad = rs.getInt("cantidad_etapas");
                double kilometros = rs.getDouble("kilometros_totales");

                System.out.printf("%-15s %-20d %-20.2f%n", tipo, cantidad, kilometros);
            }

            IO.println("------------------------------------------------------------");
        } catch (SQLException sqle) {
            IO.println("\nError al calcular el resumen de las etapas.");
            IO.println(sqle.getMessage());
        }
    }
}
