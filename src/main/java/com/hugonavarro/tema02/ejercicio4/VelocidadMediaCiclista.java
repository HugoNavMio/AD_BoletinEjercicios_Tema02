package com.hugonavarro.tema02.ejercicio4;

import com.hugonavarro.tema02.Conexion;
import com.hugonavarro.tema02.ejercicio1.ListarEquipos;

import java.sql.*;
import java.util.Scanner;

public class VelocidadMediaCiclista {
    public static void velocidadMediaCiclista() {
        Scanner sc = new Scanner(System.in);
        ListarEquipos.listarEquipos();

        IO.println("\n============================");
        IO.println("VELOCIDAD MEDIA DEL CICLISTA");
        IO.println("============================");

        IO.print("\nIntroduzca el ID del equipo: ");

        String entrada = sc.nextLine().trim();
        int idEquipo;

        try {
            idEquipo = Integer.parseInt(entrada);

            if (idEquipo <= 0) {
                IO.println("\nEl ID del equipo debe ser mayor que 0.");
                return;
            }
        } catch (NumberFormatException nfe) {
            IO.println("\nSe debe introducir un número entero válido.");
            return;
        }

        MostrarCiclistasDeUnEquipo.mostrarCiclistasDeUnEquipo(idEquipo);

        IO.print("\nIntroduzca el ID del ciclista: ");

        entrada = sc.nextLine().trim();
        int idCiclista;

        try {
            idCiclista = Integer.parseInt(entrada);

            if (idCiclista <= 0) {
                IO.println("\nEl ID del ciclista debe ser mayor que 0.");
                return;
            }
        } catch (NumberFormatException nfe) {
            IO.println("\nSe debe introducir un número entero válido.");
            return;
        }

        String sql = """
                SELECT
                    c.id_ciclista,
                    c.nombre AS ciclista,
                    e.nombre AS equipo,
                    SUM(et.distancia_km) AS distancia_total,
                    SUM(EXTRACT(EPOCH FROM re.tiempo)) AS tiempo_total_segundos,
                    (
                        SUM(et.distancia_km) * 3600
                        / NULLIF(SUM(EXTRACT(EPOCH FROM re.tiempo)), 0)
                    ) AS velocidad_media
                FROM resultados_etapa re
                INNER JOIN ciclistas c
                    ON re.id_ciclista = c.id_ciclista
                INNER JOIN equipos e
                    ON c.id_equipo = e.id_equipo
                INNER JOIN etapas et
                    ON re.id_etapa = et.id_etapa
                WHERE c.id_ciclista = ?
                    AND c.id_equipo = ?
                    AND re.estado = 'FINALIZADO'
                GROUP BY c.id_ciclista, c.nombre, e.nombre
                """;

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql)
        ) {
            stmt.setInt(1, idCiclista);
            stmt.setInt(2, idEquipo);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    String nombre = rs.getString("ciclista");
                    String equipo = rs.getString("equipo");
                    double distancia = rs.getDouble("distancia_total");
                    double tiempoSegundos = rs.getDouble("tiempo_total_segundos");
                    double velocidad = rs.getDouble("velocidad_media");

                    double tiempoHoras = tiempoSegundos / 3600.0;

                    IO.println("\n======================");
                    IO.println("RESULTADO DE VELOCIDAD");
                    IO.println("======================");

                    IO.println("\nCiclista: " + nombre);
                    IO.println("Equipo: " + equipo);

                    System.out.printf("Distancia total: %.2f km%n", distancia);
                    System.out.printf("Tiempo total: %.2f horas%n", tiempoHoras);
                    System.out.printf("Velocidad media: %.2f km/h%n", velocidad);

                    IO.println("---------------------------");
                } else {
                    IO.println("\nNo se encontraron resultados para ese ciclista.");
                    IO.println("Comprueba que el ID del ciclista pertenezca al equipo seleccionado.");
                }
            }
        } catch (SQLException sqle) {
            IO.println("\nError al calcular la velocidad media.");
            IO.println(sqle.getMessage());
        }
    }
}
