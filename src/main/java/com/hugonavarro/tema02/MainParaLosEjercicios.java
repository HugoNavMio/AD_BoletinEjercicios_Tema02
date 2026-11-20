package com.hugonavarro.tema02;

import java.sql.*;
import java.util.Scanner;

public class MainParaLosEjercicios {
    static void main() {
        Scanner sc = new Scanner(System.in);
        int opcion;

        do {
            IO.println("\n================");
            IO.println("VUELTA ATLÁNTICA");
            IO.println("================");
            IO.println("\nOPCIONES A ELEGIR:");
            IO.println("\n1. Listar equipos");
            IO.println("2. Ciclistas por equipo");
            IO.println("3. Listar etapas");
            IO.println("0. Salir");
            IO.println("-----------------");
            IO.print("Seleccione una opción: ");

            opcion = sc.nextInt();

            switch (opcion) {
                case 1:
                    listarEquipos();
                    break;
                case 2:
                    ciclistasPorEquipo();
                    break;
                case 3:
                    listarEtapas();
                    break;
                case 0:
                    IO.println("\nSaliendo...");
                    break;
                default:
                    IO.println("\nOpción no válida.");
                    break;
            }
        } while (opcion != 0);

        sc.close();
    }

    // Ejercicio 1

    private static void listarEquipos() {
        String sql = "SELECT * FROM equipos";

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()
        ) {
            IO.println("\n==================");
            IO.println("LISTADO DE EQUIPOS");
            IO.println("==================");

            System.out.printf("\n%-10s %-35s %-20s%n", "ID", "NOMBRE", "PAÍS");

            IO.println("------------------------------------------------------------");

            boolean hayEquipos = false;

            while (rs.next()) {
                hayEquipos = true;

                int id = rs.getInt("id_equipo");
                String nombre = rs.getString("nombre");
                String pais = rs.getString("pais");

                System.out.printf("%-10s %-35s %-20s%n", id, nombre, pais);
            }

            if (!hayEquipos) {
                IO.println("No hay equipos registrados.");
            }

            IO.println("------------------------------------------------------------");
        } catch (SQLException sqle) {
            IO.println("\nError al consultar los equipos.");
            IO.println(sqle.getMessage());
        }
    }

    // Ejercicio 2

    private static void ciclistasPorEquipo() {
        Scanner sc = new Scanner(System.in);
        listarEquipos();

        IO.println("\n====================");
        IO.println("CICLISTAS POR EQUIPO");
        IO.println("====================");

        IO.println("\nIntroduzca el ID del equipo.");
        IO.println("Introduzca \"0\" para mostrar todos los ciclistas.");
        IO.print("ID del equipo: ");

        String entrada = sc.nextLine().trim();
        int idEquipo;

        try {
            idEquipo = Integer.parseInt(entrada);

            if (idEquipo < 0) {
                IO.println("\nEl ID del equipo no puede ser negativo.");
                return;
            }
        } catch (NumberFormatException nfe) {
            IO.println("\nSe debe introducir un número entero válido.");
            return;
        }

        String sql = """
                SELECT
                    c.id_ciclista,
                    c.nombre,
                    c.pais,
                    e.nombre AS equipo
                FROM ciclistas c
                INNER JOIN equipos e
                    ON c.id_equipo = e.id_equipo
                WHERE (? = 0 OR c.id_equipo = ?)
                ORDER BY e.nombre, c.nombre;
                """;

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql)
        ) {
            stmt.setInt(1, idEquipo);
            stmt.setInt(2, idEquipo);

            try (ResultSet rs = stmt.executeQuery()) {
                IO.println("\n====================");
                IO.println("LISTADO DE CICLISTAS");
                IO.println("====================");

                System.out.printf("\n%-12s %-30s %-12s %-30s%n", "ID", "CICLISTA", "PAÍS", "EQUIPO");

                IO.println("------------------------------------------------------------------------------------------");

                boolean hayCiclistas = false;

                while (rs.next()) {
                    hayCiclistas = true;

                    int idCiclista = rs.getInt("id_ciclista");
                    String nombre = rs.getString("nombre");
                    String pais = rs.getString("pais");
                    String equipo = rs.getString("equipo");

                    System.out.printf("%-12d %-30s %-12s %-30s%n", idCiclista, nombre, pais, equipo);
                }

                if (!hayCiclistas) {
                    IO.println("No se encontraron ciclistas para el equipo indicado.");
                }

                IO.println("------------------------------------------------------------------------------------------");
            }
        } catch (SQLException sqle) {
            IO.println("\nError al consultar los ciclistas.");
            IO.println(sqle.getMessage());
        }
    }

    // Ejercicio 3

    private static void listarEtapas() {
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

        resumenEtapasPorTipo();
    }

    private static void resumenEtapasPorTipo() {
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
