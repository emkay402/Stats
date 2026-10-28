from manim import *
from manim_slides import Slide
from manim_slides.slide.animation import Zoom
import numpy as np
np.random.seed(42)


class MySlide(Slide):
    skip_reversing = True
    def next_part(self):
        d = [Dot(color=PURE_MAGENTA).to_corner(UL, 0), Dot(color=PURE_MAGENTA).to_corner(UR, 0),
             Dot(color=PURE_MAGENTA).to_corner(DL, 0), Dot(color=PURE_MAGENTA).to_corner(DR, 0)]
        
        self.add(*[x for x in d])
        self.play(*[x.animate.center() for x in d], run_time=0.5) 
        self.play(*[FadeOut(mobj) for mobj in self.mobjects], run_time=0.5)

    def onward(self, new_sub: Tex, to_rem):
        if type(to_rem) is not list:
            to_rem = [to_rem]
        origin = {0: 'cor', 1: 'edge'}

        d = Dot(color=PURE_MAGENTA).to_corner(corner=DL if (1 & np.random.randint(0, 2)) else UL, buff=0) if 1 & np.random.randint(0, 2) else Dot(color=PURE_MAGENTA).to_edge(edge=[LEFT, UP, DOWN][np.random.randint(0, 3)])
        self.add(d)
        self.play(d.animate.center(), run_time=0.5) 
        self.play(d.animate.to_edge(RIGHT, buff=-1), run_time=0.5)
        self.play((Uncreate(d), *[FadeOut(mobj) for mobj in to_rem]), run_time=0.5)
        subt = new_sub.scale(0.65).center()
        self.play(Write(subt))
        self.play(subt.animate.to_corner(UL)) 
        return subt

    def intro(self, title, subtitle):
        dot = Dot()



        self.play(Create(dot))
        self.next_slide(loop=True)
        self.play(Indicate(dot, color=PURE_MAGENTA))

        self.next_slide()
        self.play(dot.animate.to_edge(RIGHT, buff=-1), run_time=1)
        self.play(Uncreate(dot))
        title_text = [title.scale(0.9).center(), subtitle.scale(0.8)]
        title_text[1].next_to(title_text[0], DOWN/2.5)
        self.play(Write(title_text[0]))
        self.play(Write(title_text[1]))
        self.next_slide()

    def new_section(self, title: Tex, subtitle: Tex = None):
        tit = title.scale(0.75).center()

        
        self.play(Write(tit))
        if subtitle is not None:
            sub = subtitle.scale(0.65).next_to(tit, DOWN/2)
            self.play(Write(sub))
        self.next_slide()
        self.play(tit.animate.set_color(YELLOW))
        if subtitle is not None:
            self.play([tit.animate.to_corner(UR), sub.animate.to_corner(UL)])
        else:
            self.play(tit.animate.to_corner(UL))
        if subtitle is not None:
            return title, sub
        else:
            return title


class TitleSlide(MySlide):
    def construct(self):

        self.intro(Tex("Introduction to Statistics"), Tex("Introductory Concepts"))
        self.next_part()


class AgendaSlide(MySlide):
    def construct(self):

        tit = self.new_section(Tex("Outline"))
        bullets = BulletedList(
            "Structure \& Organization",
            "The Dataset",
            "Getting Our Hands Dirty"
        ).next_to(tit, DOWN*1.5).scale(0.6).shift(RIGHT*3)
        self.play(Write(bullets))
        
        self.next_slide()
        self.next_part()

class StructSlides(MySlide):

    def construct(self):

        tit, subt = self.new_section(Tex("Structure \& Organization"), Tex("About The Tutorials"))

        blist = BulletedList(
            "Generally speaking, the tutorial covers the topics from the preceding week",
            "The goal is to get hands-on practice with what you learn in the lecture",
            "Attending the tutorials is mandatory",
            "Submitting homeworks is not mandatory, but is highly recommended (bonus points)",
            "Homework files can be sent to the following email:",
            "Mohammed.Mahmood@edu.ruhr-uni-bochum.de",
            "Please include [Introduction to Statistics] in the title!",
            "You can find the files and relevant materials in a dedicated folder called:",
            "Tutorium Files",
            buff=0.8
        ).next_to(subt, DOWN).scale(0.6).shift(RIGHT*4+UP*2)
        blist[2].set_color(RED)
        blist[3].set_color(PURE_CYAN)
        blist[-1].set_color(PURE_MAGENTA)
        blist[6].set_color(RED)

        blist1 = BulletedList(
            "We will use MATLAB, but you will also have access to materials in Python",
            "While I don't mind receiving your homework in Python, I recommend sticking to MATLAB for consistency"

        ).next_to(subt, DOWN*1.5).scale(0.6).shift(RIGHT*4)

        for b in blist:
            self.play(Write(b))
            self.next_slide()
        self.play(Unwrite(blist))
        
        for b in blist1:
            self.play(Write(b))
            self.next_slide()    
        self.play(Unwrite(blist1))

        self.play(Write(Tex("Question: What do you think about starting 15 minutes later?").center().scale(0.75)))
        self.next_slide()
        self.play(Unwrite(self.mobjects[-1]))
        subt = self.onward(Tex("What You Can Expect"), [subt])
        
        blist = BulletedList(
            "This will be a programming class",
            "To make the most out of this class, I recommend playing around and finding out",
            "This can be in class (by following along) or at home",
            "I will present you with the tools of the trade, best practices, and answer any questions you may have :)",
            "I will try to include a recap or summary of the previous week"
        ).next_to(subt, DOWN*1.5).scale(0.6).shift(RIGHT*4)
        for b in blist:
            self.play(Write(b))
            self.next_slide()
        self.play(Unwrite(blist))

        subt = self.onward(Tex("Use of Generative AI"), [subt])
        blist = BulletedList(
            "This is more to do with you than me, I wouldn't like to play a cat and mouse game",
            "General recommendation:",
            "If you're learning something for the first time, try to keep your use of AI limited to explanation/clarification purposes, and to discuss your thoughts"
        ).next_to(subt, DOWN*1.5).scale(0.6).shift(RIGHT*4)
        blist[-1].set_color(RED)
        for b in blist:
            self.play(Write(b))
            self.next_slide()
        
        self.next_part()
        
class DataOverview(MySlide):
    def construct(self):
        tit, subt = self.new_section(Tex("The Dataset"), Tex("Overview"))
        blist = BulletedList(
            "Observational (no experiments) study involving 416 subjects",
            "Cross-Sectional: Observations were made at a single time-point",
            "Contains summary features of the MRI scans (we won't analyze images)"
        ).next_to(subt, DOWN*1.5).scale(0.6).shift(RIGHT*4)

        for b in blist:
            self.play(Write(b))
            self.next_slide()
        self.play(Unwrite(blist))

        # subt = self.onward(Tex("Recap"), subt)

        ses = Tex("Socioeconomic Status (SES)", ": Assessed by the Hollingshead Index of Social Position and classified into categories from ", "1", " (highest status) to ","5", " (lowest status)").scale(0.75).center().shift(UP)
        ses[0].set_color(PURE_CYAN)
        ses[2].set_color(RED)
        ses[4].set_color(RED)

        mmse = Tex("Mini-Mental State Examination (MMSE)", ": Ranges from ", "0", " (worst) to ","30", " (best)").scale(0.75).center().shift(UP)
        mmse[0].set_color(PURE_CYAN)
        mmse[2].set_color(RED)
        mmse[4].set_color(RED)

        etiv = Tex("Estimated Total Intracranial Volume (eTIV)", ": measure the total volume inside the skull (brain, cerebrospinal fluid, and meninges)").scale(0.75).center().shift(UP)
        mmse[0].set_color(PURE_CYAN)

        quant_or_qual = Tex("Quantitative", " or ", "Qualitative", "?").scale(0.6).center().shift(DOWN)
        quant_or_qual[0].set_color(PURE_MAGENTA)
        quant_or_qual[2].set_color(PURE_MAGENTA)

        quant = Tex("Quantitative").scale(0.6).center().shift(DOWN)
        qual = Tex("Qualitative").scale(0.6).center().shift(DOWN)

        manifest_or_latent = Tex("Manifest", " or ", "Latent", "?").scale(0.6).center().shift(DOWN)
        manifest_or_latent[0].set_color(PURE_MAGENTA)
        manifest_or_latent[2].set_color(PURE_MAGENTA)

        manifest = Tex("Manifest").scale(0.6).center().shift(DOWN)
        latent = Tex("Latent").scale(0.6).center().shift(DOWN)

        discr_or_cont = Tex("Discrete", " or ", "Continuous", "?").scale(0.6).center().shift(DOWN)
        discr = Tex("Discrete").scale(0.6).center().shift(DOWN)
        cont = Tex("Continuous").scale(0.6).center().shift(DOWN)

        # self.play(Write(ses))
        # self.next_slide()
        # self.play(Write(quant_or_qual))
        # self.next_slide()
        # self.play(ReplacementTransform(quant_or_qual, quant))

        self.next_part()


class Concl(MySlide):
    def construct(self):
        tit = self.new_section(Tex("Conclusion"))


class HW(MySlide):
    def construct(self):
        tit = self.new_section(Tex("Homework"))

        
