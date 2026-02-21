-- @author Hipólito Guzmán-Miranda
-- This code infers a Dual-Port RAM when synthesized
-- Input addresses have been defined as ``unsigned`` for convenience, but could also be defined as ``std_logic_vector`` if needed
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dpram is
  generic (
    DATA_WIDTH : integer := 8;  -- Width of the data bus
    ADDR_WIDTH : integer := 8   -- Width of the address bus
    );
  port (clk_a   : in  std_logic;                                 -- Clock signal for port A, active on rising edge
        clk_b   : in  std_logic;                                 -- Clock signal for port A, active on rising edge
        addri_a : in  unsigned (ADDR_WIDTH-1 downto 0);          -- Address for port A
        datai_a : in  std_logic_vector (DATA_WIDTH-1 downto 0);  -- Input data for port A
        we_a    : in  std_logic;                                 -- Write enable for port A
        datao_a : out std_logic_vector (DATA_WIDTH-1 downto 0);  -- Output data for port A
        addri_b : in  unsigned (ADDR_WIDTH-1 downto 0);          -- Address for port B
        datai_b : in  std_logic_vector (DATA_WIDTH-1 downto 0);  -- Input data for port B
        we_b    : in  std_logic;                                 -- Write enable for port B
        datao_b : out std_logic_vector (DATA_WIDTH-1 downto 0)   -- Output data for port B
        );
end dpram;

architecture dpram_arch of dpram is

  type ram_type is array ((2**ADDR_WIDTH)-1 downto 0) of std_logic_vector (DATA_WIDTH-1 downto 0);  -- Data type for memory contents
  signal ram : ram_type;  -- Memory contents

begin

  -- When synthesizing this process, the synthesizer infers a BRAM 
  process(clk_a, clk_b)
  begin

    if (rising_edge(clk_a)) then
      if (we_a = '1') then
        ram(to_integer(addri_a)) <= datai_a;
      end if;
      datao_a <= ram(to_integer(addri_a));
    end if;

    if (rising_edge(clk_b)) then
      if (we_b = '1') then
        ram(to_integer(addri_b)) <= datai_b;
      end if;
      datao_b <= ram(to_integer(addri_b));
    end if;

  end process;

end dpram_arch;
