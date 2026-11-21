package com.hugonavarro.tema02.ejercicio9;

import com.hugonavarro.tema02.Conexion;

import java.sql.*;

public class ClasificacionEquipos {
    public static void clasificacionEquipos() {
        String sql = """
                WITH ciclistas_ordenados AS (
                    SELECT
                        re.id_etapa,
                        c.id_equipo,
                        c.id_ciclista,
                        re.tiempo,
                        ROW_NUMBER() OVER (
                            PARTITION BY re.id_etapa, c.id_equipo
                            ORDER BY re.tiempo ASC, c.id_ciclista ASC
                        ) AS posicion
                    FROM resultados_etapa re
                    INNER JOIN ciclistas c
                        ON re.id_ciclista = c.id_ciclista
                    WHERE re.estado = 'FINALIZADO'
                ),
                tres_mejores AS (
                    SELECT
                        id_etapa,
                        id_equipo,
                        tiempo
                    FROM ciclistas_ordenados
                    WHERE posicion <= 3
                )
                SELECT
                    e.id_equipo,
                    e.nombre AS equipo,
                    SUM(tm.tiempo) AS tiempo_total
                FROM tres_mejores tm
                INNER JOIN equipos e
                    ON tm.id_equipo = e.id_equipo
                GROUP BY
                    e.id_equipo,
                    e.nombre
                ORDER BY
                    tiempo_total ASC
                """;

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()
        ) {
            IO.println("\n=================================");
            IO.println("CLASIFICACIÓN GENERAL POR EQUIPOS");
            IO.println("=================================");

            System.out.printf("\n%-10s %-35s %-25s%n", "POSICIÓN", "EQUIPO", "TIEMPO TOTAL");

            IO.println("----------------------------------------------------------------------");

            boolean hayResultados = false;
            int posicion = 1;

            while (rs.next()) {
                hayResultados = true;

                String equipo = rs.getString("equipo");
                String tiempo = rs.getString("tiempo_total");

                System.out.printf("%-10d %-35s %-25s%n", posicion, equipo, tiempo);

                posicion++;
            }

            if (!hayResultados) {
                IO.println("No hay resultados para la clasificación por equipos.");
            }

            IO.println("----------------------------------------------------------------------");
        } catch (SQLException sqle) {
            IO.println("\nError al consultar la clasificación por equipos.");
            IO.println(sqle.getMessage());
        }
    }
}
