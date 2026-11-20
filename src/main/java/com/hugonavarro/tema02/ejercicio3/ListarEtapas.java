package com.hugonavarro.tema02.ejercicio3;

import com.hugonavarro.tema02.Conexion;

import java.sql.*;

public class ListarEtapas {
    public static void listarEtapas() {
        String sql = """
                SELECT
                    id_etapa,
                    tipo,
                    fecha,
                    salida,
                    llegada,
                    distancia_km
                FROM etapas
                ORDER BY id_etapa
                """;

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()
        ) {
            IO.println("\n=================");
            IO.println("LISTADO DE ETAPAS");
            IO.println("=================");

            System.out.printf("\n%-5s %-12s %-12s %-20s %-25s %-10s%n", "ID", "TIPO", "FECHA", "SALIDA", "LLEGADA", "KM");

            IO.println("------------------------------------------------------------------------------------------");

            boolean hayEtapas = false;

            while (rs.next()) {
                hayEtapas = true;

                int id = rs.getInt("id_etapa");
                String tipo = rs.getString("tipo");
                String fecha = rs.getDate("fecha").toString();
                String salida = rs.getString("salida");
                String llegada = rs.getString("llegada");
                double kilometros = rs.getDouble("distancia_km");

                System.out.printf("%-5d %-12s %-12s %-20s %-25s %-10.2f%n", id, tipo, fecha, salida, llegada, kilometros);
            }

            if (!hayEtapas) {
                IO.println("No hay etapas registradas.");
            }

            IO.println("------------------------------------------------------------------------------------------");
        } catch (SQLException sqle) {
            IO.println("\nError al consultar las etapas.");
            IO.println(sqle.getMessage());
        }

        ResumenEtapasPorTipo.resumenEtapasPorTipo();
    }
}
