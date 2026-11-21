package com.hugonavarro.tema02;

import com.hugonavarro.tema02.ejercicio1.ListarEquipos;
import com.hugonavarro.tema02.ejercicio2.CiclistasPorEquipo;
import com.hugonavarro.tema02.ejercicio3.ListarEtapas;
import com.hugonavarro.tema02.ejercicio4.VelocidadMediaCiclista;
import com.hugonavarro.tema02.ejercicio5.ClasificacionEtapa;
import com.hugonavarro.tema02.ejercicio6.ClasificacionMontanya;
import com.hugonavarro.tema02.ejercicio7.ClasificacionRegularidad;
import com.hugonavarro.tema02.ejercicio8.ClasificacionGeneral;
import com.hugonavarro.tema02.ejercicio9.ClasificacionEquipos;

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
            IO.println("4. Velocidad media de un ciclista");
            IO.println("5. Clasificación de una etapa");
            IO.println("6. Clasificación de la monataña");
            IO.println("7. Clasificación de la regularidad");
            IO.println("8. Clasificación general");
            IO.println("9. Clasificación por equipos");
            IO.println("0. Salir");
            IO.println("--------------------");
            IO.print("Seleccione una opción: ");

            opcion = sc.nextInt();

            switch (opcion) {
                case 1:
                    ListarEquipos.listarEquipos();
                    break;
                case 2:
                    CiclistasPorEquipo.ciclistasPorEquipo();
                    break;
                case 3:
                    ListarEtapas.listarEtapas();
                    break;
                case 4:
                    VelocidadMediaCiclista.velocidadMediaCiclista();
                    break;
                case 5:
                    ClasificacionEtapa.clasificacionEtapa();
                    break;
                case 6:
                    ClasificacionMontanya.clasificacionMontanya();
                    break;
                case 7:
                    ClasificacionRegularidad.clasificacionRegularidad();
                    break;
                case 8:
                    ClasificacionGeneral.clasificacionGeneral();
                    break;
                case 9:
                    ClasificacionEquipos.clasificacionEquipos();
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
}
