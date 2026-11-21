package com.hugonavarro.tema02.ejercicio8;

import com.hugonavarro.tema02.Conexion;

import java.sql.*;

public class ClasificacionGeneral {
    public static void clasificacionGeneral() {
        String sql = """
                SELECT
                    c.id_ciclista,
                    c.nombre AS ciclista,
                    e.nombre AS equipo,
                    SUM(re.tiempo) AS tiempo_total
                FROM resultados_etapa re
                INNER JOIN ciclistas c
                    ON re.id_ciclista = c.id_ciclista
                INNER JOIN equipos e
                    ON c.id_equipo = e.id_equipo
                WHERE re.estado = 'FINALIZADO'
                GROUP BY
                    c.id_ciclista,
                    c.nombre,
                    e.nombre
                ORDER BY
                    tiempo_total ASC
                """;

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()
        ) {
            IO.println("\n=====================");
            IO.println("CLASIFICACIÓN GENERAL");
            IO.println("=====================");

            System.out.printf("\n%-10s %-30s %-30s %-20s%n", "POSICIÓN", "CICLISTA", "EQUIPO", "TIEMPO TOTAL");

            IO.println("------------------------------------------------------------------------------------------");

            boolean hayResultados = false;
            int posicion = 1;

            while (rs.next()) {
                hayResultados = true;

                String ciclista = rs.getString("ciclista");
                String equipo = rs.getString("equipo");
                String tiempo = rs.getString("tiempo_total");

                System.out.printf("%-10d %-30s %-30s %-20s%n", posicion, ciclista, equipo, tiempo);

                posicion++;
            }

            if (!hayResultados) {
                IO.println("No hay tiempos registrados en la clasificación general.");
            }

            IO.println("------------------------------------------------------------------------------------------");
        } catch (SQLException sqle) {
            IO.println("\nError al consultar la clasificación general.");
            IO.println(sqle.getMessage());
        }
    }
}
